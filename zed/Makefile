name := zed
# Discovery: https://github.com/zed-industries/zed/releases/latest
version := 1.1.7
archive_url := https://github.com/zed-industries/zed/releases/download/v$(version)/zed-linux-x86_64.tar.gz
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)
version_dir := $(data_dir)/$(version)
app_dir := $(version_dir)/zed.app

.PHONY: install
install: \
	~/.local/bin/zed \
	~/.local/share/applications/dev.zed.Zed.desktop \
	~/.local/share/icons/hicolor/512x512/apps/zed.png \
	~/.config/zed/settings.json \
	~/.config/zed/keymap.json

$(app_dir)/bin/zed:
	$(info [$(name)] Downloading $(version)...)
	@mkdir -p $(version_dir)
	@curl -fsSL $(archive_url) | tar -C $(version_dir) -xzf -

.PHONY: ~/.local/bin/zed
~/.local/bin/zed: $(app_dir)/bin/zed
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.local/share/applications/dev.zed.Zed.desktop
~/.local/share/applications/dev.zed.Zed.desktop: $(app_dir)/bin/zed
	$(info [$(name)] Installing desktop entry...)
	@mkdir -p $(dir $@)
	@sed 's|Icon=zed|Icon=$(app_dir)/share/icons/hicolor/512x512/apps/zed.png|; s|Exec=zed|Exec=$(app_dir)/bin/zed|' \
		$(app_dir)/share/applications/dev.zed.Zed.desktop > $@

.PHONY: ~/.local/share/icons/hicolor/512x512/apps/zed.png
~/.local/share/icons/hicolor/512x512/apps/zed.png: $(app_dir)/bin/zed
	$(info [$(name)] Installing icon...)
	@mkdir -p $(dir $@)
	@ln -fsT $(app_dir)/share/icons/hicolor/512x512/apps/zed.png $@

.PHONY: ~/.config/zed/settings.json
~/.config/zed/settings.json: settings.json
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.config/zed/keymap.json
~/.config/zed/keymap.json: keymap.json
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@
