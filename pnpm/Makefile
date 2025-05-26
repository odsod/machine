name := pnpm

.PHONY: install-packages
install-packages: ~/.config/environment.d/10-$(name).conf
	$(info [$(name)] Installing packages...)
	@sudo dnf install -y pnpm

.PHONY: ~/.config/environment.d/10-$(name).conf
~/.config/environment.d/10-$(name).conf: environment.conf
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@
