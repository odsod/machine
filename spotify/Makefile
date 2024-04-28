name := spotify
gpg_key_url := https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg
keyring := /etc/apt/trusted.gpg.d/spotify.gpg
apt_sources_list := /etc/apt/sources.list.d/spotify.list
apt_source := deb http://repository.spotify.com stable non-free

.PHONY: install-package
install-package: $(apt_sources_list)
	$(info [$(name)] Installing package...)
	@sudo apt-get install -y \
		spotify-client \
		| sed -e "s/^/[$(name):$@] /"

$(apt_sources_list): $(keyring)
	$(info [$(name)] Adding APT sources list...)
	@echo "$(apt_source)" | sudo tee $@ > /dev/null
	@sudo apt-get update | sed -e "s/^/[$(name):sources.list.d] /"

$(keyring):
	$(info [$(name)] Adding GPG key...)
	@curl -fsSL $(gpg_key_url) | sudo gpg --dearmor -o $@
