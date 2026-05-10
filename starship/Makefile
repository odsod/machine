name := starship
# Discovery: https://github.com/starship/starship/releases/latest
version := 1.25.1
archive_url := https://github.com/starship/starship/releases/download/v$(version)/starship-x86_64-unknown-linux-gnu.tar.gz
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)
version_dir := $(data_dir)/$(version)

.PHONY: install
install: ~/.local/bin/starship ~/.config/starship.toml ~/.config/fish/conf.d/starship.fish

$(version_dir)/starship:
	$(info [$(name)] Downloading $(version)...)
	@mkdir -p $(version_dir)
	@curl -fsSL $(archive_url) | tar -C $(version_dir) -xzf -
	@chmod +x $@

.PHONY: ~/.local/bin/starship
~/.local/bin/starship: $(version_dir)/starship
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.config/starship.toml
~/.config/starship.toml: starship.toml
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.config/fish/conf.d/starship.fish
~/.config/fish/conf.d/starship.fish: $(version_dir)/starship
	$(info [$(name)] Generating fish init...)
	@mkdir -p $(dir $@)
	@$(version_dir)/starship init fish --print-full-init > $@
