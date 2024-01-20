obsidian_version := 1.5.3
obsidian_deb_url := https://github.com/obsidianmd/obsidian-releases/releases/download/v$(obsidian_version)/obsidian_$(obsidian_version)_amd64.deb

.PHONY: install
install: install-package

.PHONY: install-package
install-package: build/$(obsidian_version)/obsidian.deb
	@sudo dpkg -i $<

build/$(obsidian_version)/obsidian.deb:
	$(info [obsidian] downloading deb...)
	@curl $(obsidian_deb_url) --create-dirs -Lo $@
	@touch $@
