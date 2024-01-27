name := docker
dist := $(shell cat /etc/os-release | grep ^VERSION_CODENAME | cut -d'=' -f2)
user := $(shell whoami)
group := docker

.PHONY: all
all: install-packages configure-group

.PHONY: configure-group
configure-group:
	$(info [$(name)] Configuring group...)
	@sudo groupadd -f $(group)
	@sudo usermod -aG $(group) $(user)

.PHONY: install-packages
install-packages: /etc/apt/sources.list.d/$(name).list
	$(info [$(name)] Installing packages...)
	@sudo apt-get install -y \
		docker-ce \
		docker-ce-cli \
		containerd.io \
		docker-buildx-plugin \
		docker-compose-plugin | sed -e "s/^/[$(name):$@] /"

/etc/apt/sources.list.d/$(name).list: /etc/apt/keyrings/$(name).asc
	$(info [$(name)] Adding APT sources list...)
	@echo "deb [arch=amd64 signed-by=$<] https://download.docker.com/linux/ubuntu $(dist) stable" | sudo tee $@ > /dev/null
	@sudo apt-get update | sed -e "s/^/[$(name):$@] /"

/etc/apt/keyrings/$(name).asc:
	$(info [$(name)] Installing key...)
	@sudo install -m 0755 -d /etc/apt/keyrings
	@sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
	@sudo chmod a+r /etc/apt/keyrings/docker.asc
