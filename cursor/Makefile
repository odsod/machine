name := cursor
appimage_url := https://downloads.cursor.com/production/031e7e0ff1e2eda9c1a0f5df67d44053b059c5df/linux/x64/Cursor-1.2.1-x86_64.AppImage

.PHONY: ~/.local/bin/cursor
~/.local/bin/cursor: build/cursor.AppImage ~/.config/Cursor/User/settings.json
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.config/Cursor/User/settings.json
~/.config/Cursor/User/settings.json: ../vscode/settings.json
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
