name := shellcheck
version := 0.10.0
archive_url := https://github.com/koalaman/shellcheck/releases/download/v$(version)/shellcheck-v$(version).linux.x86_64.tar.xz
archive := build/$(version)/archive.tar.xz
cmd := build/$(version)/shellcheck-v$(version)/$(name)
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
