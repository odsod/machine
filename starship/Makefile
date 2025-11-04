name := starship

.PHONY: ~/.config/starship.toml
~/.config/starship.toml: starship.toml install-package
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: install-package
install-package:
	$(info [$(name)] Installing package $@...)
	@dnf copr enable atim/starship
	@sudo dnf install starship --repo copr:copr.fedorainfracloud.org:atim:starship
