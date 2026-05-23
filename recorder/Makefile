name := recorder
hostname := $(shell hostnamectl --static 2>/dev/null || hostname -s)

# Discovery: https://github.com/odsod/recorder/commits/main
version := bb2e740

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
	@go install github.com/odsod/recorder/cmd/recorder@$(version)

.PHONY: install-config
install-config: $(HOME)/.config/recorder/config.json

.PHONY: $(HOME)/.config/recorder/config.json
$(HOME)/.config/recorder/config.json: hosts/$(hostname).json
	$(info [$(name)] Symlinking host config for $(hostname)...)
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
