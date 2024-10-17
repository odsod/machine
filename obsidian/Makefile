name := obsidian
version := 1.7.4
deb_url := https://github.com/obsidianmd/obsidian-releases/releases/download/v$(version)/obsidian_$(version)_amd64.deb

.PHONY: install-package
install-package: build/$(version)/package.deb
	$(info [$(name)] Installing package...)
	@sudo dpkg -i $<

build/$(version)/package.deb:
	$(info [$(name)] Downloading package...)
	@curl $(deb_url) --create-dirs -Lo $@
	@touch $@
