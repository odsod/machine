name := jwt-cli
version := 6.2.0
archive_url := https://github.com/mike-engel/jwt-cli/releases/download/$(version)/jwt-linux.tar.gz

.PHONY: ~/.local/bin/jwt
~/.local/bin/jwt: build/$(version)/jwt
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

build/$(version)/jwt: build/$(version)/archive.tar.gz
	$(info [$(name)] Extracting archive...)
	@tar -C $(dir $<) -xf $<
	@touch $@
	@chmod +x $@

build/$(version)/archive.tar.gz:
	$(info [$(name)] Downloading archive...)
	@curl $(archive_url) --create-dirs -Lo $@
	@touch $@
