name := etcher
version := 1.19.25
appimage_url := https://github.com/balena-io/etcher/releases/download/v$(version)/balenaEtcher-$(version)-x64.AppImage

.PHONY: ~/.local/bin/$(name)
~/.local/bin/$(name): build/$(version)/$(name).appimage
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

build/$(version)/$(name).appimage:
	$(info [$(name)] Downloading AppImage...)
	@curl $(appimage_url) --create-dirs -Lo $@
	@touch $@
	@chmod +x $@
