name := machine

.PHONY: install
install: \
	~/.profile \
	install-packages \
	install-modules

.PHONY: ~/.profile
~/.profile: profile
	$(info [$(name)] symlinking $@...)
	@ln -fsT $(abspath $<) $@

.PHONY: install-packages
install-packages:
	$(info [$(name)] Installing packages...)
	@sudo apt-get install -y \
		apt-transport-https \
		ca-certificates \
		curl \
		fd-find \
		git \
		gnupg \
		keepassxc \
		qbittorrent \
		ripgrep \
		wl-clipboard \
		| sed -e "s/^/[${name}:$@] /"

.PHONY: install-modules
install-modules:
	$(info [$(name)] Installing modules...)
	@find . -mindepth 2 -maxdepth 2 -name Makefile | xargs dirname | xargs -n1 make -C
