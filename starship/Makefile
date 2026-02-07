name := starship

.PHONY: ~/.config/starship.toml
~/.config/starship.toml: starship.toml install-package
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: install-package
install-package:
	$(info [$(name)] Installing package $@...)
	@sudo dnf install -y starship
