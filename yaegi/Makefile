name := yaegi
version := 0.16.1
archive_url := https://github.com/traefik/yaegi/releases/download/v$(version)/yaegi_v$(version)_linux_amd64.tar.gz
archive := build/$(version)/archive.tar.gz
cmd := build/$(version)/yaegi
symlink := ~/.local/bin/$(name)

.PHONY: $(symlink)
$(symlink): $(cmd)
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

$(cmd): $(archive)
	$(info [$(name)] Extracting $(archive)...)
	@tar -C $(dir $<) -xf $<
	@touch $@
	@chmod +x $@

$(archive):
	$(info [$(name)] Downloading $(archive_url)...)
	@curl $(archive_url) --create-dirs -Lo $@
	@touch $@
