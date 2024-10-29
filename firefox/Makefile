name := firefox

.PHONY: install-packages
install-packages: /etc/apt/sources.list.d/mozilla.list /etc/apt/preferences.d/mozilla
	$(info [$(name)] Installing packages...)
	@sudo apt-get install -y firefox \
		| sed -e "s/^/[$(name):$@] /"

/etc/apt/preferences.d/mozilla:
	$(info [$(name)] Prioritizing packages...)
	@echo '
	Package: *
	Pin: origin packages.mozilla.org
	Pin-Priority: 1000
	' | sudo tee $@

/etc/apt/sources.list.d/mozilla.list: /etc/apt/keyrings/packages.mozilla.org.asc
	$(info [$(name)] Adding APT sources list...)
	@echo "deb [signed-by=$<] https://packages.mozilla.org/apt mozilla main" | sudo tee $@ > /dev/null
	@sudo apt-get update | sed -e "s/^/[$(name)] /"

/etc/apt/keyrings/packages.mozilla.org.asc:
	$(info [$(name)] Installing key...)
	@sudo install -d -m 0755 /etc/apt/keyrings
	@wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee $@ > /dev/null
