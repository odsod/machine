name := rust
environment := ~/.config/environment.d/10-$(name).conf

.PHONY: install-packages
install-packages: $(environment)
	$(info [$(name)] Installing packages...)
	@sudo dnf install -y rustup

.PHONY: $(environment)
$(environment): environment.conf
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@
