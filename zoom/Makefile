name := zoom
version := 6.3.6.6315
deb_url := https://zoom.us/client/$(version)/zoom_amd64.deb

.PHONY: install-package
install-package: build/$(version)/package.deb
	$(info [$(name)] Installing package...)
	@sudo dpkg -i $<

build/$(version)/package.deb:
	$(info [$(name)] Downloading package...)
	@curl $(deb_url) --create-dirs -Lo $@
	@touch $@
