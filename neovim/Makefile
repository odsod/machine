name := neovim

.PHONY: all
all: \
	install-packages \
	update-alternatives \
	~/.config/nvim \
	install-plugins

.PHONY: install-plugins
install-plugins: ~/.config/nvim
	$(info [$(name)] Installing plugins...)
	@nvim --headless "+Lazy! sync" +qa

.PHONY: update-alternatives
update-alternatives:
	@sudo rm /usr/bin/vim
	@sudo rm /usr/bin/vi
	@sudo update-alternatives --install /usr/bin/vim vim $(shell which nvim) 10
	@sudo update-alternatives --install /usr/bin/vi vi $(shell which nvim) 10
	@sudo update-alternatives --set vim /usr/bin/nvim
	@sudo update-alternatives --set vi /usr/bin/nvim

.PHONY: install-packages
install-packages:
	$(info [$(name)] Installing packages...)
	@sudo dnf install -y neovim gcc-c++ tree-sitter-cli

.PHONY: ~/.config/nvim
~/.config/nvim:
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@rm -rf $@
	@ln -fsT $(abspath .) $@
