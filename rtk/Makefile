name := rtk
# Discovery: https://github.com/rtk-ai/rtk/releases/latest
version := 0.39.0
archive_url := https://github.com/rtk-ai/rtk/releases/download/v$(version)/rtk-x86_64-unknown-linux-musl.tar.gz
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: all
all: ~/.local/bin/$(name)

.PHONY: ~/.local/bin/$(name)
~/.local/bin/$(name): $(data_dir)/$(version)/$(name)
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

$(data_dir)/$(version)/$(name): $(data_dir)/$(version)/archive.tar.gz
	$(info [$(name)] Extracting $<...)
	@tar -C $(dir $<) -xf $<
	@touch $@
	@chmod +x $@

$(data_dir)/$(version)/archive.tar.gz:
	$(info [$(name)] Downloading $(archive_url)...)
	@curl $(archive_url) --create-dirs -Lo $@
