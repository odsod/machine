.PHONY: install
install: \
	install-deps \
	install-alacritty \
	install-bash \
	install-iosevka \
	install-neovim \
	install-tmux

.PHONY: install-deps
install-deps:
	sudo apt install ripgrep fd-find

.PHONY: install-alacritty
install-tmux:
	make -C alacritty

.PHONY: install-bash
install-bash:
	make -C bash

.PHONY: install-iosevka
install-iosevka:
	make -C iosevka

.PHONY: install-neovim
install-neovim:
	make -C neovim

.PHONY: install-tmux
install-tmux:
	make -C tmux
