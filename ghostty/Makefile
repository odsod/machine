name := ghostty

.PHONY: install-packages
install-packages: ~/.config/ghostty/config ~/.config/ghostty/themes
	$(info [$(name)] Installing packages...)
	@sudo dnf install -y ghostty

.PHONY: ~/.config/ghostty/config
~/.config/ghostty/config: config
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.config/ghostty/themes
~/.config/ghostty/themes: themes
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@
