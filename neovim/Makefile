.PHONY: install
install: \
	install-packages \
	~/.config/nvim/init.vim \
	~/.local/share/nvim/site/autoload/plug.vim \
	~/.config/environment.d/10-odsod-desktop-neovim.conf

.PHONY: install-packages
install-packages:
	$(info [neovim] installing packages)
	@sudo apt install -y neovim >/dev/null 2>&1

~/.local/share/nvim/site/autoload/plug.vim:
	$(info [neovim] installing plug.vim)
	@mkdir -p $(dir $@)
	@curl -o $@ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

.PHONY: ~/.config/environment.d/10-odsod-desktop-neovim.conf
~/.config/environment.d/10-odsod-desktop-neovim.conf:
	$(info [neovim] writing $@)
	@mkdir -p $(dir $@)
	@echo EDITOR=vim > $@

.PHONY: ~/.config/nvim/init.vim
~/.config/nvim/init.vim: init.vim
	$(info [neovim] symlinking $@)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@
