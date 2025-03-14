name := wireshark

.PHONY: configure-group
configure-group: install-package
	$(info [$(name)] Configuring group...)
	@sudo groupadd -f wireshark
	@sudo usermod -aG wireshark $(shell whoami)

.PHONY: install-package
install-package:
	$(info [$(name)] Installing package...)
	@sudo dnf install -y wireshark
