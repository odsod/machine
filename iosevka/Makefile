name := iosevka
version := 28.0.5
archive_url := https://github.com/be5invis/Iosevka/releases/download/v$(version)/PkgTTC-Iosevka-$(version).zip

.PHONY: ~/.local/share/fonts/iosevka
~/.local/share/fonts/iosevka: build/$(version)/Iosevka-Regular.ttc
	$(info [$(name)] Installing fonts...)
	@mkdir -p ~/.local/share/fonts
	@ln -fs $(abspath $(dir $<)) $@
	@fc-cache -vf >/dev/null

build/$(version)/Iosevka-Regular.ttc: build/$(version)/iosevka.zip
	$(info [$(name)] Unzipping...)
	@unzip -d $(dir $@) $<
	@touch $@

build/$(version)/iosevka.zip:
	$(info [$(name)] Downloading archive...)
	@curl $(archive_url) --create-dirs -Lo $@
	@touch $@
