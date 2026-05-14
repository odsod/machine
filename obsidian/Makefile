name := obsidian
# Discovery: https://github.com/obsidianmd/obsidian-releases/releases/latest
version := 1.12.7
appimage_url := https://github.com/obsidianmd/obsidian-releases/releases/download/v$(version)/Obsidian-$(version).AppImage
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)
config := $(HOME)/.config/obsidian/obsidian.json
vault_path := $(HOME)/Vaults/odsod

.PHONY: install
install: ~/.local/bin/obsidian-app ~/.local/bin/obsidian $(config)

.PHONY: ~/.local/bin/obsidian-app
~/.local/bin/obsidian-app: $(data_dir)/$(version)/app.AppImage
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

$(data_dir)/$(version)/obsidian-cli: $(data_dir)/$(version)/app.AppImage
	$(info [$(name)] Extracting CLI binary...)
	@cd /tmp && $< --appimage-extract obsidian-cli >/dev/null 2>&1
	@install -m 755 /tmp/squashfs-root/obsidian-cli $@
	@rm -rf /tmp/squashfs-root

$(data_dir)/current: $(data_dir)/$(version)/obsidian-cli
	@ln -fsT $(abspath $(data_dir)/$(version)) $@

~/.local/bin/obsidian: obsidian-wrapper.sh $(data_dir)/current
	$(info [$(name)] Installing CLI wrapper...)
	@mkdir -p $(dir $@)
	@install -m 755 obsidian-wrapper.sh $@

.PHONY: $(config)
$(config):
	$(info [$(name)] Configuring vault and CLI...)
	@mkdir -p $(dir $@)
	@if [ ! -f $@ ]; then echo '{}' > $@; fi
	@jq --arg path "$(vault_path)" 'if (.vaults // {} | to_entries | map(select(.value.path == $$path)) | length) == 0 then .vaults.odsod = {"path": $$path, "open": true} else . end | .cli = true' $@ > $@.tmp && mv $@.tmp $@

$(data_dir)/$(version)/app.AppImage:
	$(info [$(name)] Downloading AppImage...)
	@curl $(appimage_url) --create-dirs -Lo $@
	@touch $@
	@chmod +x $@
