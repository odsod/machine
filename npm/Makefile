name := npm

.PHONY: install-packages
install-packages: ~/.config/environment.d/10-$(name).conf ~/.npmrc
	$(info [$(name)] Installing packages...)
	@sudo dnf install -y nodejs-npm

.PHONY: ~/.npmrc
~/.npmrc: npmrc
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.config/environment.d/10-$(name).conf
~/.config/environment.d/10-$(name).conf: environment.conf
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@
