.PHONY: install
install: \
	install-packages \
	install-bash \
	install-inter \
	install-inter-display \
	install-dropbox \
	install-git \
	install-iosevka \
	install-keyboard \
	install-konsole \
	install-neovim \
	install-tmux \
	install-vscode

.PHONY: install-packages
install-packages:
	$(info [desktop] installing packages)
	@sudo apt install -y \
		keepassxc \
		wl-clipboard \
		ripgrep \
		fd-find \
	 >/dev/null 2>&1

install-%:
	@make -sC $(subst install-,,$@)
