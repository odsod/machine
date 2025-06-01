name := java
version := 21
environment := ~/.config/environment.d/10-$(name).conf

.PHONY: install-packages
install-packages: $(environment)
	$(info [$(name)] Installing packages...)
	@sudo dnf install -y java-$(version)-openjdk

.PHONY: $(environment)
$(environment): environment.conf
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@
