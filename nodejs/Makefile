name := nodejs
version := 22.x

.PHONY: install-package
install-package: /etc/apt/sources.list.d/nodesource.list
	$(info [$(name)] Installing package...)
	@sudo apt-get install -y \
		nodejs \
		| sed -e "s/^/[$(name):$@] /"

.PHONY: /etc/apt/sources.list.d/nodesource.list
/etc/apt/sources.list.d/nodesource.list: /usr/share/keyrings/nodesource.gpg
	$(info [$(name)] Adding APT sources list...)
	@echo "deb [arch=amd64 signed-by=$<] https://deb.nodesource.com/node_$(version) nodistro main" | sudo tee $@ > /dev/null
	@sudo apt-get update | sed -e "s/^/[$(name)] /"

/usr/share/keyrings/nodesource.gpg:
	$(info [$(name)] Adding GPG key...)
	@curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o $@
