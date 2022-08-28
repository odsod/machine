.PHONY: install
install: \
	install-deps \
	~/.config/tmux/tmux.conf

.PHONY: install-deps
install-deps:
	sudo apt install tmux

~/.config/tmux/tmux.conf: tmux.conf
	mkdir -p $(dir $@)
	ln -fs $(abspath $<) $@
