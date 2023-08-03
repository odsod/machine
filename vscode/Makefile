.PHONY: install
install: \
	install-extensions \
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

.PHONY: install-extensions
install-extensions:
	@code --install-extension arcticicestudio.nord-visual-studio-code
	@code --install-extension be5invis.toml
	@code --install-extension golang.go
	@code --install-extension ms-python.python
	@code --install-extension ms-python.vscode-pylance
	@code --install-extension vscodevim.vim
	@code --install-extension zxh404.vscode-proto3
