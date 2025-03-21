name := ghostty

.PHONY: install-packages
install-packages: ~/.config/ghostty/config
	$(info [$(name)] Installing packages...)
	@sudo dnf copr enable -y pgdev/ghostty
	@sudo dnf install -y ghostty

.PHONY: ~/.config/ghostty/config
~/.config/ghostty/config: config
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@
