name := recorder

# Discovery: https://github.com/snakers4/silero-vad/releases/latest
silero_vad_version := 5.1.2
silero_vad_url := https://github.com/snakers4/silero-vad/raw/v$(silero_vad_version)/src/silero_vad/data/silero_vad.onnx
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: install
install: install-dependencies install-model install-tool install-config install-toggle install-shortcut

.PHONY: install-dependencies
install-dependencies:
	$(info [$(name)] Installing dependencies...)
	@sudo dnf install -y -q \
		libnotify \
		pipewire-utils \
		pulseaudio-utils

$(data_dir)/silero_vad.onnx:
	$(info [$(name)] Downloading Silero VAD ONNX model v$(silero_vad_version)...)
	@mkdir -p $(data_dir)
	@curl -fL "$(silero_vad_url)" -o $@

.PHONY: install-model
install-model: $(data_dir)/silero_vad.onnx

.PHONY: install-tool
install-tool:
	$(info [$(name)] Installing recorder via uv tool...)
	@$(MAKE) -C ../uv install-packages
	@uv tool install -e $(CURDIR)

.PHONY: install-config
install-config: $(HOME)/.config/recorder/config.toml

$(HOME)/.config/recorder/config.toml: config.toml
	$(info [$(name)] Installing default config...)
	@mkdir -p $(dir $@)
	@cp -n $< $@

.PHONY: install-toggle
install-toggle: $(HOME)/.local/bin/recorder-toggle

$(HOME)/.local/bin/recorder-toggle: recorder-toggle
	$(info [$(name)] Installing toggle script...)
	@install -m 0755 $< $@

.PHONY: install-shortcut
install-shortcut:
	$(info [$(name)] Registering KDE global shortcut (Meta+Shift+M)...)
	@if ! kreadconfig6 --file kglobalshortcutsrc --group "recorder-toggle.desktop" --key "_launch" 2>/dev/null | grep -q "Meta+Shift+M"; then \
		kwriteconfig6 --file kglobalshortcutsrc --group "recorder-toggle.desktop" --key "_launch" "Meta+Shift+M,none,Toggle Recorder"; \
		kwriteconfig6 --file kglobalshortcutsrc --group "recorder-toggle.desktop" --key "_k_friendly_name" "Toggle Recorder"; \
	fi
