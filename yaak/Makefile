name := yaak
version := 2026.1.2
package_url := https://github.com/mountain-loop/yaak/releases/download/v$(version)/yaak-$(version)-1.x86_64.rpm

.PHONY: install-package
install-package: build/$(version)/package.rpm
	$(info [$(name)] Installing package...)
	@sudo dnf install -y $<

build/$(version)/package.rpm:
	$(info [$(name)] Downloading package...)
	@curl $(package_url) --create-dirs -Lo $@
	@touch $@
