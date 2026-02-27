name := obsidian
# Discovery: https://github.com/obsidianmd/obsidian-releases/releases/latest
version := 1.12.4
appimage_url := https://github.com/obsidianmd/obsidian-releases/releases/download/v$(version)/Obsidian-$(version).AppImage
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: ~/.local/bin/obsidian
~/.local/bin/obsidian: $(data_dir)/$(version)/app.AppImage
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

$(data_dir)/$(version)/app.AppImage:
	$(info [$(name)] Downloading AppImage...)
	@curl $(appimage_url) --create-dirs -Lo $@
	@touch $@
	@chmod +x $@
