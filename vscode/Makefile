name := vscode
gpg_key_url := https://packages.microsoft.com/keys/microsoft.asc
keyring := /etc/apt/keyrings/packages.microsoft.gpg
apt_sources_list := /etc/apt/sources.list.d/$(name).list
apt_source := deb [arch=amd64 signed-by=$(keyring)] https://packages.microsoft.com/repos/code stable main

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

.PHONY: install-package
install-package: $(apt_sources_list)
	$(info [$(name)] Installing package...)
	@sudo apt-get install -y \
		code \
		| sed -e "s/^/[$(name):$@] /"

$(apt_sources_list): $(keyring)
	$(info [$(name)] Adding APT sources list...)
	@echo "$(apt_source)" | sudo tee $@ > /dev/null
	@sudo apt-get update | sed -e "s/^/[$(name):sources.list.d] /"

$(keyring):
	$(info [$(name)] Adding GPG key...)
	@curl -fsSL $(gpg_key_url) | sudo gpg --dearmor -o $@
