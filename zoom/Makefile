name := zoom
# Discovery: https://support.zoom.com/hc/en/article?id=zm_kb&sysparm_article=KB0061222
version := 6.7.2.6498
package_url := https://zoom.us/client/$(version)/zoom_x86_64.rpm

.PHONY: install-package
install-package: build/$(version)/package.rpm
	$(info [$(name)] Installing package...)
	@sudo dnf install -y $<

build/$(version)/package.rpm:
	$(info [$(name)] Downloading package...)
	@curl $(package_url) --create-dirs -Lo $@
	@touch $@
