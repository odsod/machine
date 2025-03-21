name := vscode

.PHONY: install
install: \
	install-package \
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
	@code --install-extension arcticicestudio.nord-visual-studio-code --force
	@code --install-extension be5invis.toml --force
	@code --install-extension golang.go --force
	@code --install-extension ms-python.python --force
	@code --install-extension vscodevim.vim --force
	@code --install-extension bufbuild.vscode-buf --force
	@code --install-extension bierner.markdown-mermaid --force

.PHONY: install-package
install-package: /etc/yum.repos.d/vscode.repo
	$(info [$(name)] Installing package...)
	@sudo dnf install -y code

/etc/yum.repos.d/vscode.repo: vscode.repo
	$(info [$(name)] Installing repo...)
	@sudo cp -f $< $@
	@dnf check-update
