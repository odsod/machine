iosevka_version := 16.0.2
iosevka_releases_url := https://github.com/be5invis/Iosevka/releases/download/v$(iosevka_version)

.PHONY: install
install: \
	.build/ttf-iosevka-$(iosevka_version)/iosevka-regular.ttf \
	.build/ttf-iosevka-fixed-$(iosevka_version)/iosevka-fixed-regular.ttf \
	.build/ttf-iosevka-term-$(iosevka_version)/iosevka-term-regular.ttf
	mkdir -p ~/.local/share/fonts
	ln -fsT $(abspath .build/ttf-iosevka-$(iosevka_version)) ~/.local/share/fonts/iosevka
	ln -fsT $(abspath .build/ttf-iosevka-fixed-$(iosevka_version)) ~/.local/share/fonts/iosevka-fixed
	ln -fsT $(abspath .build/ttf-iosevka-term-$(iosevka_version)) ~/.local/share/fonts/iosevka-term
	fc-cache -vf

%.zip:
	curl \
		$(iosevka_releases_url)/ttf-$(notdir $(basename $@))-$(iosevka_version).zip \
		--create-dirs -Lo $@

%-regular.ttf: %.zip
	unzip -d $(dir $@) $<
