name := docker

.PHONY: configure-permissions
configure-permissions: install-packages
	$(info [$(name)] Configuring permissions...)
	@sudo groupadd -f docker
	@sudo usermod -aG docker $(shell whoami)

.PHONY: install-packages
install-packages:
	$(info [$(name)] Installing packages...)
	@sudo dnf install -y docker-cli containerd docker-compose docker-buildx
	@sudo systemctl enable --now docker
