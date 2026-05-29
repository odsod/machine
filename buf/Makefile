name := buf
# Discovery: https://github.com/bufbuild/buf/releases/latest
version := 1.70.0
archive_url := https://github.com/bufbuild/buf/releases/download/v$(version)/buf-Linux-x86_64.tar.gz
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

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

.PHONY: discover
discover:
	@printf 'version=%s\n' "$$(curl -sI https://github.com/bufbuild/buf/releases/latest \
		| grep -i ^location: | grep -oP '/v\K[0-9][0-9a-z.-]+' || echo UNKNOWN)"
