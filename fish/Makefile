name := fish

.PHONY: change-shell
change-shell: install-package
	$(info [$(name)] Changing login shell...)
	@chsh -s $(shell which fish)

.PHONY: install-package
install-package:
	$(info [$(name)] Installing package...)
	@sudo dnf install -y fish >/dev/null 2>&1

.PHONY: ~/.config/fish/config.fish
~/.config/fish/config.fish: config.fish
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@
