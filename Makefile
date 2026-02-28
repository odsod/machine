name := machine

.PHONY: install
install: \
	~/.profile \
	~/.config/plasma-workspace/env/odsod-machine.sh \
	install-packages \
	install-flatpak-packages \
	install-agents \
	install-modules


.PHONY: ~/.profile
~/.profile: env.sh
	$(info [$(name)] Symlinking $@...)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.config/plasma-workspace/env/odsod-machine.sh
~/.config/plasma-workspace/env/odsod-machine.sh: env.sh
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: install-packages
install-packages:
	$(info [$(name)] Installing packages...)
	@sudo dnf install \
		bat \
		ca-certificates \
		curl \
		difftastic \
		dnf5-plugins \
		dos2unix \
		fd-find \
		fedora-workstation-repositories \
		firefox \
		flatpak \
		fzf \
		gifsicle \
		git \
		git-delta \
		hexyl \
		htop \
		iftop \
		intel-media-driver \
		java-25-openjdk-devel \
		jq \
		keepassxc \
		maven \
		ncdu \
		ngrep \
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
		wl-clipboard \
		yt-dlp \
		-y -q

.PHONY: install-flatpak-packages
install-flatpak-packages:
	$(info [$(name)] Installing Flatpak packages...)
	@flatpak install flathub \
		com.spotify.Client

.PHONY: install-agents
install-agents:
	$(info [$(name)] Installing agents...)
	@test -d .agents/.jj || \
		jj git clone git@github.com:odsod/agents.git .agents
	@$(MAKE) -C .agents

.PHONY: install-modules
install-modules:
	$(info [$(name)] Installing modules...)
	@find . -mindepth 2 -maxdepth 2 -name Makefile | xargs dirname | xargs -n1 make -C

.PHONY: install-sudoers
install-sudoers:
	$(info [$(name)] Installing sudoers for odsod...)
	@printf '%s\n' 'odsod ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/odsod >/dev/null
	@sudo chmod 0440 /etc/sudoers.d/odsod
	@sudo visudo -cf /etc/sudoers.d/odsod
