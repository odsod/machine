name := zed

.PHONY: install-packages
install-packages: ~/.config/zed/settings.json ~/.config/zed/keymap.json
	$(info [$(name)] Installing packages...)
	@sudo dnf install -y zed zed-cli --repo terra

.PHONY: ~/.config/zed/settings.json
~/.config/zed/settings.json: settings.json
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.config/zed/keymap.json
~/.config/zed/keymap.json: keymap.json
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@
