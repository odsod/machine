.PHONY: install
install: \
	install-packages \
	install-bash \
	install-dropbox \
	install-git \
	install-inter \
	install-interception \
	install-iosevka \
	install-keyboard \
	install-konsole \
	install-kwin \
	install-neovim \
	install-tmux \
	install-vscode

.PHONY: install-packages
install-packages:
	$(info [desktop] installing packages...)
	@sudo apt install -y \
		git \
		curl \
		qbittorrent \
		keepassxc \
		wl-clipboard \
		ripgrep \
		fd-find \
	 >/dev/null 2>&1

install-%:
	@make -sC $(subst install-,,$@)
