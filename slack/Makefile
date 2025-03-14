name := slack
version := 4.41.105
build := 4.41.105-0.1.el8
package_url := https://downloads.slack-edge.com/desktop-releases/linux/x64/$(version)/slack-$(build).x86_64.rpm

.PHONY: install-package
install-package: build/$(version)/package.rpm
	$(info [$(name)] Installing package...)
	@sudo dnf install $<

build/$(version)/package.rpm:
	$(info [$(name)] Downloading package...)
	@curl $(package_url) --create-dirs -Lo $@
	@touch $@
