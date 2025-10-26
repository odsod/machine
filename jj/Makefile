name := jj
version := 0.34.0
archive_url := https://github.com/jj-vcs/jj/releases/download/v$(version)/jj-v$(version)-x86_64-unknown-linux-musl.tar.gz

.PHONY: ~/.local/bin/$(name)
~/.local/bin/$(name): build/$(version)/jj ~/.config/jj/config.toml
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.config/jj/config.toml
~/.config/jj/config.toml: config.toml
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

build/$(version)/jj: build/$(version)/archive.tar.gz
	$(info [$(name)] Extracting $<...)
	@tar -C $(dir $<) -xf $<
	@touch $@
	@chmod +x $@

build/$(version)/archive.tar.gz:
	$(info [$(name)] Downloading $(archive_url)...)
	@curl $(archive_url) --create-dirs -Lo $@
	@touch $@
