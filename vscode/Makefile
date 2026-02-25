name := vscode
include extensions.mk

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
	@for ext in $(EDITOR_EXTENSIONS); do \
		code --install-extension $$ext --force; \
	done

.PHONY: install-package
install-package: /etc/yum.repos.d/vscode.repo
	$(info [$(name)] Installing package...)
	@if ! rpm -q code >/dev/null 2>&1; then \
		sudo dnf install -y code; \
	fi

/etc/yum.repos.d/vscode.repo: vscode.repo
	$(info [$(name)] Installing repo...)
	@sudo cp -f $< $@
	@dnf check-update
