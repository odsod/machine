name := shellcheck
version := 0.9.0
archive_url := https://github.com/koalaman/shellcheck/releases/download/v$(version)/shellcheck-v$(version).linux.x86_64.tar.xz
archive := build/$(version)/archive.tar.xz
cmd := build/$(version)/shellcheck-v$(version)/$(name)
symlink := ~/.local/bin/$(name)

.PHONY: $(symlink)
$(symlink): $(cmd)
	$(info [$(name)] symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

$(cmd): $(archive)
	$(info [$(name)] extracting $(archive)...)
	@tar -C $(dir $<) -xf $<
	@touch $@
	@chmod +x $@

$(archive):
	$(info [$(name)] downloading $(archive_url)...)
	@curl $(archive_url) --create-dirs -Lo $@
	@touch $@
