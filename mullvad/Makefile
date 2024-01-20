name := mullvad
version := 2023.6
deb_url := https://github.com/mullvad/mullvadvpn-app/releases/download/$(version)/MullvadVPN-$(version)_amd64.deb

.PHONY: install
install: install-package

.PHONY: install-package
install-package: build/$(version)/package.deb
	$(info [$(name)] installing package...)
	@sudo dpkg -i $<

build/$(version)/package.deb:
	$(info [$(name)] downloading package...)
	@curl $(deb_url) --create-dirs -Lo $@
	@touch $@
