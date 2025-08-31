name := zed

.PHONY: ~/.config/zed/settings.json
~/.config/zed/settings.json: settings.json
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@
