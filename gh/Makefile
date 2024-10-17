name := gh
version := 2.59.0
archive_url := https://github.com/cli/cli/releases/download/v$(version)/gh_$(version)_linux_amd64.tar.gz
archive := build/$(version)/archive.tar.gz
cmd := build/$(version)/gh_$(version)_linux_amd64/bin/gh
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
