.PHONY: install
install: \
	install-deps \
	~/.config/alacritty/alacritty.yml \
	~/.local/bin/alacrittymux \
	install-bash \
	install-iosevka \
	install-neovim \
	install-tmux

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

.PHONY: install-deps
install-deps:
	sudo add-apt-repository ppa:mmstick76/alacritty
	sudo apt install -y tmux alacritty

~/.config/alacritty/alacritty.yml: alacritty.yml
	mkdir -p $(dir $@)
	ln -fs $(abspath $<) $@

~/.local/bin/alacrittymux: alacrittymux
	mkdir -p $(dir $@)
	ln -fs $(abspath $<) $@
