name := machine

.PHONY: install
install: \
	install-packages \
	install-modules

.PHONY: install-packages
install-packages:
	$(info [$(name)] Installing packages...)
	@sudo apt-get install -y \
		git \
		curl \
		qbittorrent \
		keepassxc \
		wl-clipboard \
		ripgrep \
		fd-find \
		| sed -e "s/^/[${name}:$@] /"

.PHONY: install-modules
install-modules:
	$(info [$(name)] Installing modules...)
	@find . -mindepth 2 -maxdepth 2 -name Makefile | xargs dirname | xargs -n1 make -C
