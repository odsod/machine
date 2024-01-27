name := syncthing
gpg_key_url := https://syncthing.net/release-key.gpg
service := syncthing.service
service_symlink := ~/.config/systemd/user/$(service)

.PHONY: all
all: install-package $(service_symlink)

.PHONY: $(service_symlink)
$(service_symlink): $(service)
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@
	@systemctl --user enable $(service)
	@systemctl --user start $(service)

.PHONY: install-package
install-package: /etc/apt/sources.list.d/syncthing.list
	$(info [$(name)] Installing package...)
	@sudo apt-get install syncthing | sed -e "s/^/[$(name):$@] /"

/etc/apt/sources.list.d/syncthing.list: syncthing.list /etc/apt/keyrings/syncthing-archive-keyring.gpg
	$(info [$(name)] Adding APT sources...)
	@sudo ln -fsT $(abspath $<) $@
	@sudo apt update

/etc/apt/keyrings/syncthing-archive-keyring.gpg:
	$(info [$(name)] Fetching GPG key...)
	@sudo mkdir -p $(dir $@)
	@sudo curl -L -o $@ $(gpg_key_url)
	@sudo touch $@
