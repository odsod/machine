name := cursor
appimage_url := https://downloads.cursor.com/production/af58d92614edb1f72bdd756615d131bf8dfa5299/linux/x64/Cursor-1.4.5-x86_64.AppImage

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

.PHONY: ~/.config/Cursor/User/keybindings.json
~/.config/Cursor/User/keybindings.json: ../vscode/keybindings.json
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
