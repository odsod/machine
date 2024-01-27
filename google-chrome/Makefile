name := google-chrome

.PHONY: install-packages
install-packages: /etc/apt/sources.list.d/google-chrome.list
	$(info [$(name)] Installing packages...)
	@sudo apt-get install -y google-chrome-stable \
		| sed -e "s/^/[$(name):$@] /"

/etc/apt/sources.list.d/google-chrome.list: /etc/apt/trusted.gpg.d/google.asc
	$(info [$(name)] Adding APT sources list...)
	@echo "deb [arch=amd64 signed-by=$<] https://dl.google.com/linux/chrome/deb/ stable main" | sudo tee $@ > /dev/null
	@sudo apt-get update | sed -e "s/^/[$(name)] /"

/etc/apt/trusted.gpg.d/google.asc:
	$(info [$(name)] Installing key...)
	@sudo curl -fsSL https://dl.google.com/linux/linux_signing_key.pub -o $@
