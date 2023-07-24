.PHONY: install
install: \
	~/.config/Code/User/settings.json

.PHONY: ~/.config/Code/User/settings.json
~/.config/Code/User/settings.json: settings.json
	$(info [vscode] symlinking $@)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@
