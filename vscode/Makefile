.PHONY: install
install: \
	~/.config/Code/User/settings.json \
	~/.config/Code/User/keybindings.json

.PHONY: ~/.config/Code/User/settings.json
~/.config/Code/User/settings.json: settings.json
	$(info [vscode] symlinking $@)
	@mkdir -p $(dir $@)
	@ln -fT $(abspath $<) $@

.PHONY: ~/.config/Code/User/keybindings.json
~/.config/Code/User/keybindings.json: keybindings.json
	$(info [vscode] symlinking $@)
	@mkdir -p $(dir $@)
	@ln -fT $(abspath $<) $@
