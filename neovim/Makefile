name := neovim
environment := ~/.config/environment.d/10-$(name).conf

.PHONY: all
all: \
	install-packages \
	update-alternatives \
	~/.config/nvim/init.lua \
	~/.local/share/nvim/site/autoload/plug.vim \
	~/.config/environment.d/10-$(name).conf

.PHONY: update-alternatives
update-alternatives:
	@sudo update-alternatives --install /usr/bin/vim vim $(shell which nvim) 10
	@sudo update-alternatives --install /usr/bin/vi vi $(shell which nvim) 10
	@sudo update-alternatives --set vim /usr/bin/nvim
	@sudo update-alternatives --set vi /usr/bin/nvim

.PHONY: install-packages
install-packages:
	$(info [$(name)] Installing packages...)
	@sudo dnf install -y neovim

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
