name := jetbrains-toolbox
version := 2.6.2.41321
archive_url := https://download.jetbrains.com/toolbox/jetbrains-toolbox-$(version).tar.gz

.PHONY: ~/.local/bin/jetbrains-toolbox
~/.local/bin/jetbrains-toolbox: build/$(version)/jetbrains-toolbox-$(version)/jetbrains-toolbox
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

build/$(version)/jetbrains-toolbox-$(version)/jetbrains-toolbox: build/$(version)/archive.tar.gz
	$(info [$(name)] Extracting archive...)
	@tar -C $(dir $<) -xf $<
	@touch $@
	@chmod +x $@

build/$(version)/archive.tar.gz:
	$(info [$(name)] Downloading archive...)
	@curl $(archive_url) --create-dirs -Lo $@
	@touch $@
