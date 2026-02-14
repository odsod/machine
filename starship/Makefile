name := starship

.PHONY: install
install: ~/.config/starship.toml ~/.config/fish/conf.d/starship.fish

.PHONY: ~/.config/starship.toml
~/.config/starship.toml: starship.toml install-packages
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.config/fish/conf.d/starship.fish
~/.config/fish/conf.d/starship.fish: install-packages
	$(info [$(name)] Generating fish init...)
	@mkdir -p $(dir $@)
	@starship init fish --print-full-init > $@

.PHONY: install-packages
install-packages:
	$(info [$(name)] Installing package...)
	@sudo dnf install -y starship
