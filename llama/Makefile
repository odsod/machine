name := llama
# Discovery: https://github.com/ggml-org/llama.cpp/releases/latest
version := b9174
source_url := https://github.com/ggml-org/llama.cpp/archive/refs/tags/$(version).tar.gz
# Discovery: https://huggingface.co/unsloth/Qwen3.5-9B-GGUF/tree/main
model := Qwen3.5-9B-Q5_K_M.gguf
model_url := https://huggingface.co/unsloth/Qwen3.5-9B-GGUF/resolve/main/$(model)
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)
build_dir := $(CURDIR)/llama.cpp-$(version)/build
port := 8179
# Bootstrap shells may not have loaded env.sh yet, so force-source the repo copy.
has_radeon_dgpu := $(shell env -u ODSOD_MACHINE sh -c '. ../env.sh >/dev/null 2>&1; printf "%s" "$$ODSOD_HAS_RADEON_DGPU"')

.PHONY: install install-radeon
ifeq ($(has_radeon_dgpu),1)
install: install-radeon
install-radeon: install-packages build $(data_dir)/$(model) install-service
else
# Desktop hosts the ROCm llama-server on its dedicated Radeon card.
# Laptops skip this module and use odsod-desktop:8179 over Tailscale.
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
build: llama.cpp-$(version)
	$(info [$(name)] Building llama-server with ROCm/HIP...)
	@cd llama.cpp-$(version) && cmake -B build \
		-DGGML_HIP=ON \
		-DCMAKE_HIP_ARCHITECTURES=gfx1200 \
		-DGGML_NATIVE=ON \
		-DCMAKE_BUILD_TYPE=Release
	@cmake --build $(build_dir) --target llama-server -j$$(nproc)

llama.cpp-$(version):
	$(info [$(name)] Downloading source...)
	@curl -fL $(source_url) | tar xz

.PHONY: install-service
install-service: build $(data_dir)/$(model)
	$(info [$(name)] Installing systemd user service...)
	@mkdir -p $(HOME)/.config/systemd/user
	@sed \
		-e 's|@SERVER_BIN@|$(build_dir)/bin/llama-server|' \
		-e 's|@MODEL_PATH@|$(data_dir)/$(model)|' \
		-e 's|@PORT@|$(port)|' \
		llama-server.service > $(HOME)/.config/systemd/user/llama-server.service
	@systemctl --user daemon-reload
	@systemctl --user enable --now llama-server.service

$(data_dir)/$(model):
	$(info [$(name)] Downloading model...)
	@curl -fL $(model_url) --create-dirs -o $@

# Usage: make download-model URL=https://huggingface.co/.../resolve/main/Model.gguf
.PHONY: download-model
download-model:
	$(info [$(name)] Downloading $(notdir $(URL))...)
	@curl -fL $(URL) --create-dirs -o $(data_dir)/$(notdir $(URL))

.PHONY: clean
clean:
	rm -rf llama.cpp-$(version)
