name := syncthing
gpg_key_url := https://syncthing.net/release-key.gpg

.PHONY: install-package
install-package: /etc/apt/sources.list.d/syncthing.list
	$(info [$(name)] installing package...)
	@sudo apt install syncthing

/etc/apt/sources.list.d/syncthing.list: syncthing.list /etc/apt/keyrings/syncthing-archive-keyring.gpg
	$(info [$(name)] adding APT sources...)
	@sudo ln -fsT $(abspath $<) $@
	@sudo apt update

/etc/apt/keyrings/syncthing-archive-keyring.gpg:
	$(info [$(name)] fetching GPG key...)
	@sudo mkdir -p $(dir $@)
	@sudo curl -L -o $@ $(gpg_key_url)
	@sudo touch $@
