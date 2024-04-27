name := vscode

.PHONY: install
install: \
	install-extensions \
	~/.config/Code/User/settings.json \
	~/.config/Code/User/keybindings.json

.PHONY: ~/.config/Code/User/settings.json
~/.config/Code/User/settings.json: settings.json
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fT $(abspath $<) $@

.PHONY: ~/.config/Code/User/keybindings.json
~/.config/Code/User/keybindings.json: keybindings.json
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fT $(abspath $<) $@

.PHONY: install-extensions
install-extensions:
	$(info [$(name)] Installing extensions...)
	@code --install-extension --force arcticicestudio.nord-visual-studio-code
	@code --install-extension --force be5invis.toml
	@code --install-extension --force golang.go
	@code --install-extension --force ms-python.python
	@code --install-extension --force ms-python.vscode-pylance
	@code --install-extension --force vscodevim.vim
	@code --install-extension --force bufbuild.vscode-buf
