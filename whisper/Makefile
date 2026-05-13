name := whisper
# Discovery: https://github.com/ggerganov/whisper.cpp/releases/latest
version := 1.8.4
source_url := https://github.com/ggerganov/whisper.cpp/archive/refs/tags/v$(version).tar.gz
# Discovery: https://huggingface.co/ggerganov/whisper.cpp/tree/main
model := ggml-large-v3.bin
model_base_url := https://huggingface.co/ggerganov/whisper.cpp/resolve/main
model_url := $(model_base_url)/$(model)
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)
build_dir := $(CURDIR)/whisper.cpp-$(version)/build
port := 8178
# Bootstrap shells may not have loaded env.sh yet, so force-source the repo copy.
has_radeon_dgpu := $(shell env -u ODSOD_MACHINE sh -c '. ../env.sh >/dev/null 2>&1; printf "%s" "$$ODSOD_HAS_RADEON_DGPU"')

.PHONY: install install-radeon
ifeq ($(has_radeon_dgpu),1)
install: install-radeon
install-radeon: install-packages build $(data_dir)/$(model) install-service
else
# Desktop hosts the ROCm whisper-server on its dedicated Radeon card.
# Laptops skip this module and use odsod-desktop:8178 over Tailscale.
install install-radeon:
	$(info [$(name)] Skipping install: no dedicated Radeon GPU detected)
	@:
endif

.PHONY: install-packages
install-packages:
	$(info [$(name)] Installing build dependencies...)
	@sudo dnf install -y \
		cmake \
		gcc-c++ \
		hipblas-devel \
		hipcc \
		rocblas-devel \
		rocm-hip

.PHONY: build
build: whisper.cpp-$(version)
	$(info [$(name)] Building whisper-server with ROCm/HIP...)
	@cd whisper.cpp-$(version) && cmake -B build \
		-DWHISPER_BUILD_SERVER=ON \
		-DGGML_HIP=ON \
		-DCMAKE_HIP_ARCHITECTURES=gfx1200 \
		-DGGML_NATIVE=ON \
		-DCMAKE_BUILD_TYPE=Release
	@cmake --build $(build_dir) --target whisper-server -j$$(nproc)

whisper.cpp-$(version):
	$(info [$(name)] Downloading source...)
	@curl -fL $(source_url) | tar xz

.PHONY: install-service
install-service: build $(data_dir)/$(model)
	$(info [$(name)] Installing systemd user service...)
	@mkdir -p $(HOME)/.config/systemd/user
	@sed \
		-e 's|@SERVER_BIN@|$(build_dir)/bin/whisper-server|' \
		-e 's|@MODEL_PATH@|$(data_dir)/$(model)|' \
		-e 's|@PORT@|$(port)|' \
		whisper-server.service > $(HOME)/.config/systemd/user/whisper-server.service
	@systemctl --user daemon-reload
	@systemctl --user enable --now whisper-server.service

$(data_dir)/$(model):
	$(info [$(name)] Downloading model...)
	@curl -fL $(model_url) --create-dirs -o $@

.PHONY: download-model
download-model:
	$(info [$(name)] Downloading $(MODEL)...)
	@curl -fL $(model_base_url)/$(MODEL) --create-dirs -o $(data_dir)/$(MODEL)

.PHONY: clean
clean:
	rm -rf whisper.cpp-$(version)
