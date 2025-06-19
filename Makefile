name := machine

.PHONY: install
install: \
	~/.config/plasma-workspace/env/environment.d.sh \
	~/.config/environment.d/00-machine.conf \
	enable-rpfusion-free \
	enable-rpfusion-nonfree \
	install-packages \
	enable-flathub \
	install-modules

.PHONY: ~/.config/plasma-workspace/env/environment.d.sh
~/.config/plasma-workspace/env/environment.d.sh: environment.d.sh
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.config/environment.d/00-machine.conf
~/.config/environment.d/00-machine.conf: environment.conf
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: enable-rpmfusion-free
enable-rpmfusion-free:
	$(info [$(name)] Enabling RPM Fusion free repository...)
	@sudo dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(shell rpm -E %fedora).noarch.rpm

.PHONY: enable-rpmfusion-nonfree
enable-rpmfusion-nonfree:
	$(info [$(name)] Enabling RPM Fusion nonfree repository...)
	@sudo dnf install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(shell rpm -E %fedora).noarch.rpm

.PHONY: install-packages
install-packages: enable-rpmfusion-free enable-rpmfusion-nonfree
	$(info [$(name)] Installing packages...)
	@sudo dnf install \
		asciinema \
		ca-certificates \
		curl \
		dnf5-plugins \
		dos2unix \
		fd-find \
		fedora-workstation-repositories \
		firefox \
		flatpak \
		git \
		git-delta \
		htop \
		iftop \
		intel-media-driver \
		jq \
		keepassxc \
		ncdu \
		ngrep \
		nodejs \
		python3-devel \
		python3-pip \
		python3-virtualenv \
		python3.12 \
		qbittorrent \
		ripgrep \
		wl-clipboard \
		-y -q

.PHONY: install-amd-hardware-codecs
install-amd-hardware-codecs:
	$(info [$(name)] Installing AMD hardware codecs...)
	@sudo dnf swap mesa-va-drivers mesa-va-drivers-freeworld
	@sudo dnf swap mesa-vdpau-drivers mesa-vdpau-drivers-freeworld

.PHONY: enable-flathub
enable-flathub: install-packages
	$(info [$(name)] Enabling Flathub...)
	@flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

.PHONY: install-modules
install-modules:
	$(info [$(name)] Installing modules...)
	@find . -mindepth 2 -maxdepth 2 -name Makefile | xargs dirname | xargs -n1 make -C
