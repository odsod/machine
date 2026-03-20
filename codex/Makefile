name := codex
# Discovery: https://github.com/openai/codex/releases/latest
version := 0.116.0
archive_url := https://github.com/openai/codex/releases/download/rust-v$(version)/$(name)-x86_64-unknown-linux-musl.tar.gz
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)
config_target := $(HOME)/.codex/config.toml
sync_script := $(CURDIR)/sync-config.py

.PHONY: all
all: \
	~/.local/bin/$(name) \
	codex-config-init

.PHONY: codex-config-init
codex-config-init:
	@if [ -e "$(config_target)" ] && [ ! -L "$(config_target)" ]; then \
		printf '[%s] Keeping existing %s\n' "$(name)" "$(config_target)"; \
	else \
		printf '[%s] Initializing %s from %s\n' "$(name)" "$(config_target)" "$(abspath config.toml)"; \
		mkdir -p "$(dir $(config_target))"; \
		rm -f "$(config_target)"; \
		cp "$(abspath config.toml)" "$(config_target)"; \
	fi

.PHONY: codex-config-sync
codex-config-sync:
	@python3 "$(sync_script)" sync --base "$(abspath config.toml)" --target "$(config_target)"

.PHONY: codex-config-diff
codex-config-diff:
	@python3 "$(sync_script)" diff --base "$(abspath config.toml)" --target "$(config_target)"

.PHONY: ~/.local/bin/$(name)
~/.local/bin/$(name): $(data_dir)/$(version)/$(name)
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

$(data_dir)/$(version)/$(name): $(data_dir)/$(version)/archive.tar.gz
	$(info [$(name)] Extracting $<...)
	@tar -C $(dir $<) -xf $<
	@mv $(dir $@)/$(name)-x86_64-unknown-linux-musl $@
	@touch $@
	@chmod +x $@

$(data_dir)/$(version)/archive.tar.gz:
	$(info [$(name)] Downloading $(archive_url)...)
	@curl $(archive_url) --create-dirs -Lo $@
