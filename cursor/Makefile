name := cursor
appimage_url := https://downloads.cursor.com/production/ec408037b24566b11e6132c58bbe6ad27046eb91/linux/x64/Cursor-0.49.4-x86_64.AppImage

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
