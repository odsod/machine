name := machine

.PHONY: install
install: \
	~/.config/plasma-workspace/env/environment.d.sh \
	~/.config/environment.d/00-machine.conf \
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

.PHONY: install-packages
install-packages:
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
		jq \
		keepassxc \
		ncdu \
		ngrep \
		nodejs \
		python3-pip \
		python3-virtualenv \
		python3-devel \
		qbittorrent \
		ripgrep \
		wl-clipboard \
		-y -q

.PHONY: enable-flathub
enable-flathub: install-packages
	$(info [$(name)] Enabling Flathub...)
	@flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

.PHONY: install-modules
install-modules:
	$(info [$(name)] Installing modules...)
	@find . -mindepth 2 -maxdepth 2 -name Makefile | xargs dirname | xargs -n1 make -C
