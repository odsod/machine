#define _GNU_SOURCE
#include <limits.h>
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <linux/input.h>
#include <linux/uinput.h>
#include <poll.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/inotify.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>

#define MAX_DEVICES 32
#define MAX_POLLFD (MAX_DEVICES + 1) /* +1 for inotify */
#define HOLD_THRESHOLD_NS (150L * 1000000L)
#define TAP_TIMEOUT_NS (350L * 1000000L)
#define INPUT_DIR "/dev/input"

static volatile sig_atomic_t running = 1;

static void sighandler(int sig) {
	(void)sig;
	running = 0;
}

struct device {
	int fd;
	char path[PATH_MAX];
};

static struct device devices[MAX_DEVICES];
static int ndevices;
static int uinput_fd = -1;

enum overload_state { OL_IDLE, OL_PENDING, OL_HELD };

struct queued_event {
	int code;
	int value;
};

#define MAX_QUEUE 16

struct space_state {
	enum overload_state state;
	struct timespec pressed_at;
	int interrupted;
	struct queued_event queue[MAX_QUEUE];
	int queue_sz;
};

struct ctrl_state {
	enum overload_state state;
	struct timespec pressed_at;
	int interrupted;
};

static struct space_state space = {OL_IDLE, {0, 0}, 0, {{0, 0}}, 0};
static struct ctrl_state capslock = {OL_IDLE, {0, 0}, 0};
static struct ctrl_state leftctrl = {OL_IDLE, {0, 0}, 0};

static long elapsed_ns(struct timespec *start) {
	struct timespec now;
	clock_gettime(CLOCK_MONOTONIC, &now);
	return (now.tv_sec - start->tv_sec) * 1000000000L +
	       (now.tv_nsec - start->tv_nsec);
}

static void emit(int code, int value) {
	struct input_event ev = {.type = EV_KEY, .code = code, .value = value};
	write(uinput_fd, &ev, sizeof(ev));
}

static void syn(void) {
	struct input_event ev = {.type = EV_SYN, .code = SYN_REPORT, .value = 0};
	write(uinput_fd, &ev, sizeof(ev));
}

static void emit_meta_chord(int key_code, int value) {
	if (value == 1) {
		emit(KEY_LEFTMETA, 1);
		emit(key_code, 1);
		syn();
	} else if (value == 0) {
		emit(key_code, 0);
		emit(KEY_LEFTMETA, 0);
		syn();
	} else if (value == 2) {
		/* repeat */
		emit(key_code, 2);
		syn();
	}
}

static void emit_key(int code, int value) {
	emit(code, value);
	syn();
}

static int is_keyboard(int fd) {
	unsigned long evbits[EV_MAX / 8 / sizeof(long) + 1] = {0};
	unsigned long keybits[KEY_MAX / 8 / sizeof(long) + 1] = {0};

	if (ioctl(fd, EVIOCGBIT(0, sizeof(evbits)), evbits) < 0)
		return 0;
	if (!(evbits[0] & (1 << EV_KEY)))
		return 0;
	if (ioctl(fd, EVIOCGBIT(EV_KEY, sizeof(keybits)), keybits) < 0)
		return 0;

	/* Must have letter keys to be a keyboard (not a power button etc) */
	int has_keys = 0;
	for (int i = KEY_Q; i <= KEY_P; i++) {
		if (keybits[i / (8 * sizeof(long))] & (1UL << (i % (8 * sizeof(long)))))
			has_keys++;
	}
	return has_keys >= 5;
}

static int is_our_virtual_device(int fd) {
	struct input_id id;
	if (ioctl(fd, EVIOCGID, &id) < 0)
		return 0;
	return id.vendor == 0x4f44 && id.product == 0x4b59;
}

static int grab_device(const char *path) {
	if (ndevices >= MAX_DEVICES)
		return -1;

	int fd = open(path, O_RDONLY | O_NONBLOCK);
	if (fd < 0)
		return -1;

	if (!is_keyboard(fd) || is_our_virtual_device(fd)) {
		close(fd);
		return -1;
	}

	if (ioctl(fd, EVIOCGRAB, 1) < 0) {
		close(fd);
		return -1;
	}

	struct device *dev = &devices[ndevices++];
	dev->fd = fd;
	snprintf(dev->path, sizeof(dev->path), "%s", path);

	char name[256] = "unknown";
	ioctl(fd, EVIOCGNAME(sizeof(name)), name);
	fprintf(stderr, "[odsod-keys] grabbed: %s (%s)\n", path, name);
	return fd;
}

static void release_devices(void) {
	for (int i = 0; i < ndevices; i++) {
		ioctl(devices[i].fd, EVIOCGRAB, 0);
		close(devices[i].fd);
	}
	ndevices = 0;
}

static int setup_uinput(void) {
	int fd = open("/dev/uinput", O_WRONLY | O_NONBLOCK);
	if (fd < 0) {
		perror("open /dev/uinput");
		return -1;
	}

	ioctl(fd, UI_SET_EVBIT, EV_KEY);
	ioctl(fd, UI_SET_EVBIT, EV_SYN);
	ioctl(fd, UI_SET_EVBIT, EV_REP);

	for (int i = 0; i < KEY_MAX; i++)
		ioctl(fd, UI_SET_KEYBIT, i);

	struct uinput_setup setup = {
	    .id = {.bustype = BUS_VIRTUAL, .vendor = 0x4f44, .product = 0x4b59},
	};
	snprintf(setup.name, UINPUT_MAX_NAME_SIZE, "odsod-keys virtual keyboard");

	if (ioctl(fd, UI_DEV_SETUP, &setup) < 0 ||
	    ioctl(fd, UI_DEV_CREATE) < 0) {
		perror("uinput setup");
		close(fd);
		return -1;
	}

	return fd;
}

static void scan_devices(void) {
	DIR *dir = opendir(INPUT_DIR);
	if (!dir)
		return;

	struct dirent *ent;
	while ((ent = readdir(dir))) {
		if (strncmp(ent->d_name, "event", 5) != 0)
			continue;

		char path[PATH_MAX];
		snprintf(path, sizeof(path), "%s/%s", INPUT_DIR, ent->d_name);

		/* Skip already grabbed */
		int already = 0;
		for (int i = 0; i < ndevices; i++) {
			if (strcmp(devices[i].path, path) == 0) {
				already = 1;
				break;
			}
		}
		if (!already)
			grab_device(path);
	}
	closedir(dir);
}

static int handle_ctrl_overload(struct ctrl_state *st, int code,
                                struct input_event *ev) {
	(void)code;
	if (ev->type != EV_KEY)
		return 0;

	if (ev->code == KEY_CAPSLOCK || ev->code == KEY_LEFTCTRL) {
		if (ev->value == 1) {
			st->state = OL_PENDING;
			clock_gettime(CLOCK_MONOTONIC, &st->pressed_at);
			st->interrupted = 0;
			emit_key(KEY_LEFTCTRL, 1);
			return 1;
		} else if (ev->value == 0) {
			emit_key(KEY_LEFTCTRL, 0);
			if (st->state == OL_PENDING && !st->interrupted &&
			    elapsed_ns(&st->pressed_at) < TAP_TIMEOUT_NS) {
				emit_key(KEY_ESC, 1);
				emit_key(KEY_ESC, 0);
			}
			st->state = OL_IDLE;
			return 1;
		} else if (ev->value == 2) {
			/* repeat — emit ctrl repeat */
			emit_key(KEY_LEFTCTRL, 2);
			return 1;
		}
	}
	return 0;
}

static void flush_queue_as_tap(void) {
	emit_key(KEY_SPACE, 1);
	emit_key(KEY_SPACE, 0);
	for (int i = 0; i < space.queue_sz; i++)
		emit_key(space.queue[i].code, space.queue[i].value);
	space.queue_sz = 0;
}

static void flush_queue_as_meta(void) {
	for (int i = 0; i < space.queue_sz; i++)
		emit_meta_chord(space.queue[i].code, space.queue[i].value);
	space.queue_sz = 0;
}

static int handle_space(struct input_event *ev) {
	if (ev->type != EV_KEY)
		return 0;

	if (ev->code == KEY_SPACE) {
		if (ev->value == 1) {
			space.state = OL_PENDING;
			clock_gettime(CLOCK_MONOTONIC, &space.pressed_at);
			space.interrupted = 0;
			space.queue_sz = 0;
			return 1;
		} else if (ev->value == 0) {
			if (space.state == OL_PENDING) {
				if (elapsed_ns(&space.pressed_at) < TAP_TIMEOUT_NS) {
					flush_queue_as_tap();
				} else {
					/* Held past tap timeout, no resolution — drop queued */
					space.queue_sz = 0;
				}
			}
			/* OL_HELD: meta chords already emitted, nothing to do */
			space.state = OL_IDLE;
			return 1;
		} else if (ev->value == 2) {
			return 1;
		}
	}

	/* Another key while space is pending or held */
	if (space.state == OL_PENDING) {
		long elapsed = elapsed_ns(&space.pressed_at);
		if (ev->value == 1) {
			if (elapsed >= HOLD_THRESHOLD_NS) {
				/* Held long enough — resolve as meta */
				space.state = OL_HELD;
				flush_queue_as_meta();
				emit_meta_chord(ev->code, 1);
				return 1;
			}
			/* Still in rollover window — queue the event */
			if (space.queue_sz < MAX_QUEUE) {
				space.queue[space.queue_sz].code = ev->code;
				space.queue[space.queue_sz].value = ev->value;
				space.queue_sz++;
			}
			return 1;
		} else if (ev->value == 0) {
			/* Key released while pending — check if it was queued */
			int was_queued = 0;
			for (int i = 0; i < space.queue_sz; i++) {
				if (space.queue[i].code == ev->code) {
					was_queued = 1;
					break;
				}
			}
			if (was_queued) {
				/* A key was tapped while space pending → resolve as meta */
				space.state = OL_HELD;
				flush_queue_as_meta();
				emit_meta_chord(ev->code, 0);
				return 1;
			}
			/* Release of a key pressed before space — pass through */
			return 0;
		}
	}

	if (space.state == OL_HELD) {
		if (ev->value == 1) {
			emit_meta_chord(ev->code, 1);
			return 1;
		} else if (ev->value == 2) {
			emit_meta_chord(ev->code, 2);
			return 1;
		} else if (ev->value == 0) {
			emit_meta_chord(ev->code, 0);
			return 1;
		}
	}

	return 0;
}

static void process_event(struct input_event *ev) {
	/* Pass through non-key events */
	if (ev->type == EV_SYN)
		return;
	if (ev->type != EV_KEY) {
		struct input_event out = *ev;
		write(uinput_fd, &out, sizeof(out));
		syn();
		return;
	}

	/* Remap esc ↔ capslock */
	if (ev->code == KEY_ESC) {
		emit_key(KEY_CAPSLOCK, ev->value);
		return;
	}

	/* Handle capslock as ctrl/esc */
	if (ev->code == KEY_CAPSLOCK) {
		if (handle_ctrl_overload(&capslock, KEY_CAPSLOCK, ev))
			return;
	}

	/* Handle leftctrl as ctrl/esc */
	if (ev->code == KEY_LEFTCTRL) {
		if (handle_ctrl_overload(&leftctrl, KEY_LEFTCTRL, ev))
			return;
	}

	/* Handle space as meta-layer/space */
	if (handle_space(ev))
		return;

	/* Mark ctrl overloads as interrupted */
	if (ev->value == 1) {
		if (capslock.state == OL_PENDING)
			capslock.interrupted = 1;
		if (leftctrl.state == OL_PENDING)
			leftctrl.interrupted = 1;
	}

	/* Passthrough */
	emit_key(ev->code, ev->value);
}

int main(void) {
	signal(SIGINT, sighandler);
	signal(SIGTERM, sighandler);

	uinput_fd = setup_uinput();
	if (uinput_fd < 0)
		return 1;

	/* Brief delay for uinput device to appear before we grab */
	usleep(200000);

	scan_devices();
	if (ndevices == 0) {
		fprintf(stderr, "[odsod-keys] no keyboards found\n");
		return 1;
	}

	/* inotify for hotplug */
	int inotify_fd = inotify_init1(IN_NONBLOCK);
	if (inotify_fd >= 0)
		inotify_add_watch(inotify_fd, INPUT_DIR, IN_CREATE);

	struct pollfd pfds[MAX_POLLFD];
	while (running) {
		int npfds = 0;
		for (int i = 0; i < ndevices; i++) {
			pfds[npfds].fd = devices[i].fd;
			pfds[npfds].events = POLLIN;
			npfds++;
		}
		if (inotify_fd >= 0) {
			pfds[npfds].fd = inotify_fd;
			pfds[npfds].events = POLLIN;
			npfds++;
		}

		int ret = poll(pfds, npfds, 100);
		if (ret < 0) {
			if (errno == EINTR)
				continue;
			break;
		}

		for (int i = 0; i < npfds; i++) {
			if (!(pfds[i].revents & POLLIN))
				continue;

			/* inotify — new device */
			if (inotify_fd >= 0 && pfds[i].fd == inotify_fd) {
				char buf[4096];
				while (read(inotify_fd, buf, sizeof(buf)) > 0)
					;
				usleep(100000); /* let device settle */
				scan_devices();
				continue;
			}

			/* Read input events */
			struct input_event evs[64];
			int n = read(pfds[i].fd, evs, sizeof(evs));
			if (n <= 0) {
				/* Device disconnected — remove it */
				for (int d = 0; d < ndevices; d++) {
					if (devices[d].fd == pfds[i].fd) {
						fprintf(stderr,
						        "[odsod-keys] lost: %s\n",
						        devices[d].path);
						close(devices[d].fd);
						devices[d] = devices[--ndevices];
						break;
					}
				}
				continue;
			}

			int nevents = n / sizeof(struct input_event);
			for (int e = 0; e < nevents; e++)
				process_event(&evs[e]);
		}

	}

	release_devices();
	ioctl(uinput_fd, UI_DEV_DESTROY);
	close(uinput_fd);
	if (inotify_fd >= 0)
		close(inotify_fd);

	fprintf(stderr, "[odsod-keys] stopped\n");
	return 0;
}
