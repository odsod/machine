name := recorder

# Discovery: https://github.com/odsod/recorder/commits/main
version := 10f1040

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
install-tool:
	$(info [$(name)] Installing recorder@$(version)...)
	@go install github.com/odsod/recorder@$(version)

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
