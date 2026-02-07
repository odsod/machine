name := fish

.PHONY: change-shell
change-shell: install-package
	$(info [$(name)] Changing login shell...)
	@if [ "$$SHELL" != "$$(which fish)" ]; then \
		chsh -s $$(which fish); \
	fi

.PHONY: install-package
install-package: ~/.config/fish/config.fish
	$(info [$(name)] Installing package...)
	@sudo dnf install -y fish

.PHONY: ~/.config/fish/config.fish
~/.config/fish/config.fish: config.fish
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@
