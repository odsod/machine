name := codex
# Discovery: https://github.com/openai/codex/releases/latest
version := 0.106.0
archive_url := https://github.com/openai/codex/releases/download/rust-v$(version)/$(name)-x86_64-unknown-linux-musl.tar.gz
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: all
all: \
	~/.local/bin/$(name) \
	~/.codex/config.toml

.PHONY: ~/.codex/config.toml
~/.codex/config.toml: config.toml
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

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
