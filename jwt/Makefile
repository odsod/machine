name := jwt
version := 6.0.0
archive_url := https://github.com/mike-engel/jwt-cli/releases/download/$(version)/jwt-linux.tar.gz

.PHONY: ~/.local/bin/$(name)
~/.local/bin/$(name): build/$(version)/$(name)
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

build/$(version)/$(name): build/$(version)/archive.tar.gz
	$(info [$(name)] Extracting archive...)
	@tar -C $(dir $<) -xf $<
	@touch $@
	@chmod +x $@

build/$(version)/archive.tar.gz:
	$(info [$(name)] Downloading archive...)
	@curl $(archive_url) --create-dirs -Lo $@
	@touch $@
