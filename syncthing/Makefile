name := syncthing

.PHONY: .config/systemd/user/default.target.wants/syncthing.service
.config/systemd/user/default.target.wants/syncthing.service: install-package
	$(info [$(name)] Starting service...)
	@systemctl --user enable syncthing.service
	@systemctl --user start syncthing.service

.PHONY: install-package
install-package:
	$(info [$(name)] Installing package...)
	@sudo dnf install -y syncthing
