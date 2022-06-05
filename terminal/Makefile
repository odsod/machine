.PHONY: install
install: \
	install-deps \
	install-konsole \
	install-bash \
	install-iosevka \
	install-neovim \
	install-tmux

.PHONY: install-deps
install-deps:
	sudo apt install ripgrep fd-find

.PHONY: install-konsole
install-tmux:
	make -C konsole

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
