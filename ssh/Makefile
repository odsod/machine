name := ssh

.PHONY: install
install: \
	install-config \
	enable-sshd

.PHONY: install-config
install-config: machine.conf
	$(info [$(name)] Symlinking SSH config...)
	@sudo mkdir -p /etc/ssh/sshd_config.d
	@sudo ln -fsT $(abspath $<) /etc/ssh/sshd_config.d/01-odsod-machine.conf

.PHONY: enable-sshd
enable-sshd:
	$(info [$(name)] Ensuring sshd is enabled and running...)
	@sudo dnf install -y openssh-server
	@sudo systemctl enable --now sshd
	@sudo systemctl reload sshd
