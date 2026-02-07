name := npm

.PHONY: install-packages
install-packages: ~/.npmrc
	$(info [$(name)] Installing packages...)
	@sudo dnf install -y nodejs-npm

.PHONY: ~/.npmrc
~/.npmrc: npmrc
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@
