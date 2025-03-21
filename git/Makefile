name := git

.PHONY: ~/.gitconfig
~/.gitconfig: gitconfig install-package
	$(info [$(name)] Symlinking... $@)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: install-package
install-package:
	$(info [$(name)] Installing...)
	@sudo dnf install -y git git-delta
