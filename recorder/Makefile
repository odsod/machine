name := recorder

# Discovery: https://github.com/odsod/recorder/releases/latest
version := 2026.6.5
archive_url := https://github.com/odsod/recorder/releases/download/v$(version)/recorder_$(version)_linux_amd64.tar.gz
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: install
install: install-dependencies install-tool install-config install-scripts

.PHONY: install-dependencies
install-dependencies:
	$(info [$(name)] Installing dependencies...)
	@sudo dnf install -y -q \
		kdialog \
		pipewire-utils \
		pulseaudio-utils

.PHONY: install-tool
install-tool: $(HOME)/.local/bin/recorder

.PHONY: $(HOME)/.local/bin/recorder
$(HOME)/.local/bin/recorder: $(data_dir)/$(version)/recorder
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

$(data_dir)/$(version)/recorder: $(data_dir)/$(version)/archive.tar.gz
	$(info [$(name)] Extracting archive...)
	@tar -C $(dir $<) -xf $<
	@touch $@
	@chmod +x $@

$(data_dir)/$(version)/archive.tar.gz:
	$(info [$(name)] Downloading archive...)
	@curl -L $(archive_url) --create-dirs -o $@
	@touch $@

.PHONY: install-config
install-config: $(HOME)/.config/recorder/config.json

.PHONY: $(HOME)/.config/recorder/config.json
$(HOME)/.config/recorder/config.json: config.json
	$(info [$(name)] Symlinking config...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: install-scripts
install-scripts: $(HOME)/.local/bin/recorder-toggle $(HOME)/.local/bin/recorder-note

$(HOME)/.local/bin/recorder-toggle: recorder-toggle
	$(info [$(name)] Installing toggle script...)
	@install -m 0755 $< $@

$(HOME)/.local/bin/recorder-note: recorder-note
	$(info [$(name)] Installing note script...)
	@install -m 0755 $< $@

.PHONY: discover
discover:
	@printf 'version=%s\n' "$$(curl -sI https://github.com/odsod/recorder/releases/latest \
		| grep -i ^location: | grep -oP '/v\K[0-9][0-9a-z.-]+' || echo UNKNOWN)"
