name := google-cloud-sdk

.PHONY: install-packages
install-packages: /etc/apt/sources.list.d/$(name).list
	$(info [$(name)] Installing packages...)
	@sudo apt-get install -y \
		google-cloud-sdk \
		| sed -e "s/^/[$(name):$@] /"

/etc/apt/sources.list.d/$(name).list: /etc/apt/trusted.gpg.d/$(name).asc
	$(info [$(name)] Adding APT sources list...)
	@echo "deb [arch=amd64 signed-by=$<] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee $@ > /dev/null
	@sudo apt-get update | sed -e "s/^/[$(name)] /"

/etc/apt/trusted.gpg.d/$(name).asc:
	$(info [$(name)] Installing key...)
	@sudo curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg -o $@
