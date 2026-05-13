name := recorder
hostname := $(shell hostnamectl --static 2>/dev/null || hostname -s)
host_config := hosts/$(hostname).toml

# Discovery: https://github.com/snakers4/silero-vad/releases/latest
silero_vad_version := 5.1.2
silero_vad_url := https://github.com/snakers4/silero-vad/raw/v$(silero_vad_version)/src/silero_vad/data/silero_vad.onnx
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: install
install: install-dependencies install-model install-tool install-config install-toggle

.PHONY: install-dependencies
install-dependencies:
	$(info [$(name)] Installing dependencies...)
	@sudo dnf install -y -q \
		kdotool \
		kdialog \
		pipewire-utils \
		pulseaudio-utils \
		at-spi2-core

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

.PHONY: $(HOME)/.config/recorder/config.toml
$(HOME)/.config/recorder/config.toml:
	$(info [$(name)] Symlinking host config for $(hostname)...)
	@test -f "$(host_config)" || { echo "[$(name)] ERROR: missing $(host_config)" >&2; exit 1; }
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $(host_config)) $@

.PHONY: install-toggle
install-toggle: $(HOME)/.local/bin/recorder-toggle

$(HOME)/.local/bin/recorder-toggle: recorder-toggle
	$(info [$(name)] Installing toggle script...)
	@install -m 0755 $< $@
