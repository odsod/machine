name := neovim
# Discovery: https://github.com/neovim/neovim/releases
version := 0.12.2
archive_url := https://github.com/neovim/neovim/releases/download/v$(version)/nvim-linux-x86_64.tar.gz
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)
install_dir := $(data_dir)/$(version)/nvim-linux-x86_64

.PHONY: all
all: \
	install-packages \
	~/.local/bin/nvim \
	update-alternatives \
	~/.config/nvim \
	install-plugins

.PHONY: install-plugins
install-plugins: ~/.config/nvim
	$(info [$(name)] Installing plugins...)
	@nvim --headless "+lua vim.pack.update(nil, { force = true })" +qa

.PHONY: ~/.local/bin/nvim
~/.local/bin/nvim: $(install_dir)/bin/nvim
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

$(install_dir)/bin/nvim: $(data_dir)/$(version)/archive.tar.gz
	$(info [$(name)] Extracting $<...)
	@tar -C $(data_dir)/$(version) -xf $<
	@touch $@

$(data_dir)/$(version)/archive.tar.gz:
	$(info [$(name)] Downloading $(archive_url)...)
	@curl -L $(archive_url) --create-dirs -o $@

.PHONY: update-alternatives
update-alternatives: ~/.local/bin/nvim
	@sudo update-alternatives --remove vim /usr/bin/nvim 2>/dev/null || true
	@sudo update-alternatives --remove vi /usr/bin/nvim 2>/dev/null || true
	@sudo update-alternatives --install /usr/bin/vim vim $(HOME)/.local/bin/nvim 10
	@sudo update-alternatives --install /usr/bin/vi vi $(HOME)/.local/bin/nvim 10
	@sudo update-alternatives --set vim $(HOME)/.local/bin/nvim
	@sudo update-alternatives --set vi $(HOME)/.local/bin/nvim

.PHONY: install-packages
install-packages:
	$(info [$(name)] Installing packages...)
	@sudo dnf install -y gcc-c++ tree-sitter-cli

.PHONY: ~/.config/nvim
~/.config/nvim:
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@rm -rf $@
	@ln -fsT $(abspath .) $@
