name := mullvad-vpn
version := 2025.4
deb_url := https://github.com/mullvad/mullvadvpn-app/releases/download/$(version)/MullvadVPN-$(version)_amd64.deb

.PHONY: install-package
install-package: build/$(version)/package.deb
	$(info [$(name)] Installing package...)
	@sudo dpkg -i $<

build/$(version)/package.deb:
	$(info [$(name)] Downloading package...)
	@curl $(deb_url) --create-dirs -Lo $@
	@touch $@
