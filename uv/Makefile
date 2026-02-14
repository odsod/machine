name := uv

.PHONY: install
install: install-packages config completions

.PHONY: install-packages
install-packages:
	$(info [$(name)] Installing package...)
	@sudo dnf install uv -y -q

.PHONY: config
config: ~/.config/uv/uv.toml

.PHONY: completions
completions: ~/.config/fish/completions/uv.fish ~/.config/fish/completions/uvx.fish

.PHONY: ~/.config/uv/uv.toml
~/.config/uv/uv.toml: uv.toml
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.config/fish/completions/uv.fish
~/.config/fish/completions/uv.fish: install-packages
	$(info [$(name)] Generating fish completions for uv...)
	@mkdir -p $(dir $@)
	@uv generate-shell-completion fish > $@

.PHONY: ~/.config/fish/completions/uvx.fish
~/.config/fish/completions/uvx.fish: install-packages
	$(info [$(name)] Generating fish completions for uvx...)
	@mkdir -p $(dir $@)
	@uvx --generate-shell-completion fish > $@
