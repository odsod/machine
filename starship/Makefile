name := starship
version := 1.22.1
archive_url := https://github.com/starship/starship/releases/download/v$(version)/starship-x86_64-unknown-linux-gnu.tar.gz

.PHONY: ~/.config/starship.toml
~/.config/starship.toml: starship.toml ~/.local/bin/starship
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.local/bin/starship
~/.local/bin/starship: build/$(version)/starship
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

build/$(version)/starship: build/$(version)/archive.tar.gz
	$(info [$(name)] Extracting $<...)
	@tar -C $(dir $<) -xf $<
	@touch $@
	@chmod +x $@

build/$(version)/archive.tar.gz:
	$(info [$(name)] Downloading $(archive_url)...)
	@curl $(archive_url) --create-dirs -Lo $@
	@touch $@
