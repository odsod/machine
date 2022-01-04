iosevka_version := 10.3.0
iosevka_releases_url := https://github.com/be5invis/Iosevka/releases/download/v$(iosevka_version)

.PHONY: install
install: \
	.build/ttf-iosevka-$(iosevka_version)/iosevka-regular.ttf \
	.build/ttf-iosevka-fixed-$(iosevka_version)/iosevka-fixed-regular.ttf \
	.build/ttf-iosevka-term-$(iosevka_version)/iosevka-term-regular.ttf
	ln -fs ~/.local/share/fonts/iosevka .build/ttf-iosevka-$(iosevka_version)
	ln -fs ~/.local/share/fonts/iosevka-fixed .build/ttf-iosevka-fixed-$(iosevka_version)
	ln -fs ~/.local/share/fonts/iosevka-term .build/ttf-iosevka-term-$(iosevka_version)
	fc-cache -vf

%.zip:
	curl \
		$(iosevka_releases_url)/ttf-$(notdir $(basename $@))-$(iosevka_version).zip \
		--create-dirs -Lo $@

%-regular.ttf: %.zip
	unzip -d $(dir $@) $<
