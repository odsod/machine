name := java
# Policy: Track the latest LTS version available in Fedora repos.
version := 25
environment := ~/.config/environment.d/10-$(name).conf

.PHONY: install-packages
install-packages: $(environment)
	$(info [$(name)] Installing packages...)
	@sudo dnf install -y java-$(version)-openjdk-devel maven

.PHONY: $(environment)
$(environment): environment.conf
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@
