name := zoom
version := 6.5.0.2465
package_url := https://zoom.us/client/$(version)/zoom_x86_64.rpm

.PHONY: install-package
install-package: build/$(version)/package.rpm
	$(info [$(name)] Installing package...)
	@sudo dnf install -y $<

build/$(version)/package.rpm:
	$(info [$(name)] Downloading package...)
	@curl $(package_url) --create-dirs -Lo $@
	@touch $@
