iosevka_version := 28.0.5
iosevka_archive_url := https://github.com/be5invis/Iosevka/releases/download/v$(iosevka_version)/PkgTTC-Iosevka-$(iosevka_version).zip

.PHONY: install
install: ~/.local/share/fonts/iosevka.ttc

.PHONY: ~/.local/share/fonts/iosevka.ttc
~/.local/share/fonts/iosevka.ttc: build/$(iosevka_version)/iosevka.ttc
	$(info [iosevka] installing...)
	@mkdir -p ~/.local/share/fonts
	@ln -fs $(abspath $<) $@
	@fc-cache -vf >/dev/null

build/$(iosevka_version)/iosevka.ttc: build/$(iosevka_version)/iosevka.zip
	$(info [iosevka] unzipping...)
	@unzip -d $(dir $@) $<
	@touch $@

build/$(iosevka_version)/iosevka.zip:
	$(info [iosevka] downloading...)
	@curl $(iosevka_archive_url) --create-dirs -Lo $@
	@touch $@
