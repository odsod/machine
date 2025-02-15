name := fd
version := 10.2.0
deb_url := https://github.com/sharkdp/fd/releases/download/v$(version)/fd-musl_$(version)_amd64.deb

.PHONY: install-package
install-package: build/$(version)/package.deb
	$(info [$(name)] Installing package...)
	@sudo dpkg -i $<

build/$(version)/package.deb:
	$(info [$(name)] Downloading package...)
	@curl $(deb_url) --create-dirs -Lo $@
	@touch $@
