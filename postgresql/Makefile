name := postgresql

.PHONY: install-package
install-package: ~/.psqlrc
	$(info [$(name)] Installing package...)
	@sudo dnf install -y postgresql

.PHONY: ~/.psqlrc
~/.psqlrc: psqlrc
	$(info [$(name)] Symlinking $@...)
	@ln -fsT $(abspath $<) $@
