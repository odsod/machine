name := machine

.PHONY: install
install: \
	~/.config/plasma-workspace/env/profile.sh \
	install-packages \
	install-modules

.PHONY: ~/.config/plasma-workspace/env/profile.sh
~/.config/plasma-workspace/env/profile.sh: profile
	$(info [$(name)] Symlinking $@...)
	@ln -fsT $(abspath $<) $@

.PHONY: enable-flathub
enable-flathub: install-packages
	$(info [$(name)] Enabling Flathub...)
	@flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

.PHONY: install-packages
install-packages:
	$(info [$(name)] Installing packages...)
	@sudo dnf install
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
		qbittorrent \
		ripgrep \
		wl-clipboard \
		-y -q

.PHONY: install-modules
install-modules:
	$(info [$(name)] Installing modules...)
	@find . -mindepth 2 -maxdepth 2 -name Makefile | xargs dirname | xargs -n1 make -C
