name := delta
version := 0.18.2
archive_url := https://github.com/dandavison/delta/releases/download/$(version)/delta-$(version)-x86_64-unknown-linux-gnu.tar.gz
archive := build/$(version)/archive.tar.gz
cmd := build/$(version)/delta-$(version)-x86_64-unknown-linux-gnu/$(name)
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
