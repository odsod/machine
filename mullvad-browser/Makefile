name := mullvad-browser
version := 13.0.7
archive_url := https://github.com/mullvad/mullvad-browser/releases/download/$(version)/mullvad-browser-linux-x86_64-$(version).tar.xz

.PHONY: ~/.local/bin/mullvadbrowser
~/.local/bin/mullvadbrowser: build/$(version)/mullvad-browser/Browser/mullvadbrowser.real
	$(info [$(name)] symlinking $@)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

build/$(version)/mullvad-browser/Browser/mullvadbrowser.real: build/$(version)/archive.tar.xz
	$(info [$(name)] extracting package...)
	@tar -C $(dir $<) -xf $<
	@touch $@
	@chmod +x $@

build/$(version)/archive.tar.xz:
	$(info [$(name)] downloading archive...)
	@curl $(archive_url) --create-dirs -Lo $@
	@touch $@
