name := nodejs
version := 21.x
gpg_key_url := https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key
keyring := /usr/share/keyrings/nodesource.gpg
apt_sources_list := /etc/apt/sources.list.d/nodesource.list

.PHONY: install
install: $(apt_sources_list)
	@sudo apt-get install -y $(name) | sed -e "s/^/[$(name):$@] /"

$(apt_sources_list): $(keyring)
	@echo "deb [arch=amd64 signed-by=$<] https://deb.nodesource.com/node_$(version) nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list > /dev/null
	@sudo apt-get update | sed -e "s/^/[$(name):$@] /"

$(keyring):
	@curl -fsSL $(gpg_key_url) | sudo gpg --dearmor -o $@
