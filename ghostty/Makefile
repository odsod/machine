name := ghostty

.PHONY: install-packages
install-packages: ~/.config/ghostty/config
	$(info [$(name)] Installing packages...)
	@sudo dnf install -y ghostty --repo terra

.PHONY: ~/.config/ghostty/config
~/.config/ghostty/config: config
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@
