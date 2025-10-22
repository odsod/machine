name := btop

.PHONY: install-package
install-package: ~/.config/btop/btop.conf
	$(info [$(name)] Installing package...)
	@sudo dnf install -y btop

.PHONY: ~/.config/btop/btop.conf
~/.config/btop/btop.conf: btop.conf
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@
