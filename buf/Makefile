name := buf
version := 1.55.0
archive_url := https://github.com/bufbuild/buf/releases/download/v$(version)/buf-Linux-x86_64.tar.gz

.PHONY: ~/.local/bin/$(name)
~/.local/bin/$(name): build/$(version)/buf/bin/buf
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

build/$(version)/buf/bin/buf: build/$(version)/archive.tar.gz
	$(info [$(name)] Extracting $<...)
	@tar -C $(dir $<) -xf $<
	@touch $@
	@chmod +x $@

build/$(version)/archive.tar.gz:
	$(info [$(name)] Downloading $(archive_url)...)
	@curl $(archive_url) --create-dirs -Lo $@
	@touch $@
