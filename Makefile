.PHONY: install
install: \
	install-packages \
	install-modules

.PHONY: install-packages
install-packages:
	$(info [machine] installing packages...)
	@sudo apt install -y \
		git \
		curl \
		qbittorrent \
		keepassxc \
		wl-clipboard \
		ripgrep \
		fd-find \
	 >/dev/null 2>&1

.PHONY: install-modules
install-modules:
	$(info [machine] installing modules...)
	@find . -mindepth 2 -maxdepth 2 -name Makefile | xargs dirname | xargs -n1 make -C
