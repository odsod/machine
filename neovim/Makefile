neovim_version := 0.9.5
neovim_appimage_url := https://github.com/neovim/neovim/releases/download/v$(neovim_version)/nvim.appimage

.PHONY: install
install: \
	~/.local/bin/nvim \
	~/.local/bin/vim \
	~/.local/bin/vi \
	~/.config/nvim/init.lua \
	~/.local/share/nvim/site/autoload/plug.vim \
	~/.config/environment.d/10-odsod-desktop-neovim.conf

~/.local/share/nvim/site/autoload/plug.vim:
	$(info [neovim] installing plug.vim)
	@mkdir -p $(dir $@)
	@curl -o $@ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

.PHONY: ~/.config/environment.d/10-odsod-desktop-neovim.conf
~/.config/environment.d/10-odsod-desktop-neovim.conf:
	$(info [neovim] writing $@)
	@mkdir -p $(dir $@)
	@echo EDITOR=vim > $@

.PHONY: ~/.config/nvim/init.lua
~/.config/nvim/init.lua: init.lua
	$(info [neovim] symlinking $@)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.local/bin/nvim
~/.local/bin/nvim: build/$(neovim_version)/nvim.appimage
	$(info [neovim] symlinking $@)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.local/bin/vim
~/.local/bin/vim: build/$(neovim_version)/nvim.appimage
	$(info [neovim] symlinking $@)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.local/bin/vi
~/.local/bin/vi: build/$(neovim_version)/nvim.appimage
	$(info [neovim] symlinking $@)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

build/$(neovim_version)/nvim.appimage:
	$(info [neovim] downloading...)
	@curl $(neovim_appimage_url) --create-dirs -Lo $@
	@touch $@
	@chmod +x $@
