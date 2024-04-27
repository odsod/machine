name := mullvad-browser
version := 13.0.14
archive_url := https://github.com/mullvad/mullvad-browser/releases/download/$(version)/mullvad-browser-linux-x86_64-$(version).tar.xz

.PHONY: ~/.local/bin/mullvadbrowser
~/.local/bin/mullvadbrowser: build/$(version)/mullvad-browser/Browser/mullvadbrowser.real
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

build/$(version)/mullvad-browser/Browser/mullvadbrowser.real: build/$(version)/archive.tar.xz
	$(info [$(name)] Extracting archive...)
	@tar -C $(dir $<) -xf $<
	@touch $@
	@chmod +x $@

build/$(version)/archive.tar.xz:
	$(info [$(name)] Downloading archive...)
	@curl $(archive_url) --create-dirs -Lo $@
	@touch $@
