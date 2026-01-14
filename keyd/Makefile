name := keyd

.PHONY: install-package
install-package: /etc/keyd/default.conf
	$(info [$(name)] Installing package...)
	@sudo dnf install -y keyd

.PHONY: /etc/keyd/default.conf
/etc/keyd/default.conf: default.conf
	$(info [$(name)] Symlinking $@...)
	@sudo mkdir -p $(dir $@)
	@sudo ln -fsT $(abspath $<) $@
