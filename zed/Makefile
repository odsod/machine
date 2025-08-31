name := zed

.PHONY: install-packages
install-packages: ~/.config/zed/settings.json
	$(info [$(name)] Installing packages...)
	@sudo dnf install -y zed zed-cli --repo terra

.PHONY: ~/.config/zed/settings.json
~/.config/zed/settings.json: settings.json
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@
