name := nodejs
version := 22.x
gpg_key_url := https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key
keyring := /usr/share/keyrings/nodesource.gpg
apt_sources_list := /etc/apt/sources.list.d/nodesource.list

.PHONY: install-package
install-package: $(apt_sources_list)
	$(info [$(name)] Installing package...)
	@sudo apt-get install -y \
		nodejs \
		| sed -e "s/^/[$(name):$@] /"

.PHONY: $(apt_sources_list)
$(apt_sources_list): $(keyring)
	$(info [$(name)] Adding APT sources list...)
	@echo "deb [arch=amd64 signed-by=$<] https://deb.nodesource.com/node_$(version) nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list > /dev/null
	@sudo apt-get update | sed -e "s/^/[$(name)] /"

$(keyring):
	$(info [$(name)] Adding GPG key...)
	@curl -fsSL $(gpg_key_url) | sudo gpg --dearmor -o $@
