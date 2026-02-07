name := machine

.PHONY: install
install: \
	~/.config/environment.d/00-machine.conf \
	install-packages \
	install-flatpak-packages \
	install-modules

.PHONY: ~/.config/environment.d/00-machine.conf
~/.config/environment.d/00-machine.conf: environment.conf
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: install-packages
install-packages:
	$(info [$(name)] Installing packages...)
	@sudo dnf install \
		ca-certificates \
		curl \
		dnf5-plugins \
		dos2unix \
		fd-find \
		fedora-workstation-repositories \
		firefox \
		flatpak \
		gifsicle \
		git \
		git-delta \
		hexyl \
		htop \
		iftop \
		intel-media-driver \
		jq \
		keepassxc \
		ncdu \
		ngrep \
		nodejs \
		pdftk \
		python3-devel \
		python3-pip \
		python3-virtualenv \
		python3.12 \
		qbittorrent \
		ripgrep \
		ruff \
		simple-scan \
		ttyd \
		unrar \
		uv \
		wl-clipboard \
		yt-dlp \
		-y -q

.PHONY: enable-flathub
enable-flathub: install-packages
	$(info [$(name)] Enabling Flathub repository...)
	@flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true

.PHONY: install-flatpak-packages
install-flatpak-packages: enable-flathub
	$(info [$(name)] Installing Flatpak packages...)
	@flatpak install flathub \
		com.spotify.Client

.PHONY: install-modules
install-modules:
	$(info [$(name)] Installing modules...)
	@find . -mindepth 2 -maxdepth 2 -name Makefile | xargs dirname | xargs -n1 make -C
