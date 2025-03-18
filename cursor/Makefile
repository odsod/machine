name := cursor
appimage_url := https://downloader.cursor.sh/linux/appImage/x64

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
	@grep filename build/headers.txt
