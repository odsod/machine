name := neovim
version := 0.9.5
appimage_url := https://github.com/neovim/neovim/releases/download/v$(version)/nvim.appimage
environment := ~/.config/environment.d/10-$(name).conf

.PHONY: all
all: \
	~/.local/bin/nvim \
	~/.local/bin/vim \
	~/.local/bin/vi \
	~/.config/nvim/init.lua \
	~/.local/share/nvim/site/autoload/plug.vim \
	~/.config/environment.d/10-$(name).conf

~/.local/share/nvim/site/autoload/plug.vim:
	$(info [$(name)] Installing $@...)
	@mkdir -p $(dir $@)
	@curl -o $@ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

.PHONY: $(environment)
$(environment): environment.conf
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.config/nvim/init.lua
~/.config/nvim/init.lua: init.lua
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.local/bin/nvim
~/.local/bin/nvim: build/$(version)/nvim.appimage
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.local/bin/vim
~/.local/bin/vim: build/$(version)/nvim.appimage
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.local/bin/vi
~/.local/bin/vi: build/$(version)/nvim.appimage
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

build/$(version)/nvim.appimage:
	$(info [$(name)] Downloading...)
	@curl $(appimage_url) --create-dirs -Lo $@
	@touch $@
	@chmod +x $@
