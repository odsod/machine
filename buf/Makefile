name := buf
# https://github.com/bufbuild/buf/releases
version := 1.65.0
archive_url := https://github.com/bufbuild/buf/releases/download/v$(version)/buf-Linux-x86_64.tar.gz
data_dir := $(HOME)/.local/share/odsod/machine/$(name)

.PHONY: ~/.local/bin/$(name)
~/.local/bin/$(name): $(data_dir)/$(version)/buf/bin/buf
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

$(data_dir)/$(version)/buf/bin/buf: $(data_dir)/$(version)/archive.tar.gz
	$(info [$(name)] Extracting $<...)
	@tar -C $(dir $<) -xf $<
	@touch $@
	@chmod +x $@

$(data_dir)/$(version)/archive.tar.gz:
	$(info [$(name)] Downloading $(archive_url)...)
	@curl $(archive_url) --create-dirs -Lo $@
	@touch $@
