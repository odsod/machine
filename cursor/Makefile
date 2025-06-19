name := cursor
appimage_url := https://downloads.cursor.com/production/979ba33804ac150108481c14e0b5cb970bda3266/linux/x64/Cursor-1.1.3-x86_64.AppImage

.PHONY: ~/.local/bin/cursor
~/.local/bin/cursor: build/cursor.AppImage
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: build/cursor.AppImage
build/cursor.AppImage:
	$(info [$(name)] Downloading AppImage...)
	@mkdir -p build
	@curl -D build/headers.txt $(appimage_url) --create-dirs -Lo $@
	@touch $@
	@chmod +x $@
