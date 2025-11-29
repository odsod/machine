name := obsidian
version := 1.10.6
appimage_url := https://github.com/obsidianmd/obsidian-releases/releases/download/v$(version)/Obsidian-$(version).AppImage

.PHONY: ~/.local/bin/obsidian
~/.local/bin/obsidian: build/$(version)/app.AppImage
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

build/$(version)/app.AppImage:
	$(info [$(name)] Downloading AppImage...)
	@curl $(appimage_url) --create-dirs -Lo $@
	@touch $@
	@chmod +x $@
