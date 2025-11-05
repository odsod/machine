name := yaak
version := 2025.8.1
package_url := https://github.com/mountain-loop/yaak/releases/download/v$(version)/yaak-$(version)-1.x86_64_linux.rpm

.PHONY: install-package
install-package: build/$(version)/package.rpm
	$(info [$(name)] Installing package...)
	@sudo dnf install -y $<

build/$(version)/package.rpm:
	$(info [$(name)] Downloading package...)
	@curl $(package_url) --create-dirs -Lo $@
	@touch $@
