name := iosevka
version := 34.1.0
archive_url := https://github.com/be5invis/Iosevka/releases/download/v$(version)/PkgTTC-IosevkaSS08-$(version).zip
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: ~/.local/share/fonts/iosevka
~/.local/share/fonts/iosevka: $(data_dir)/$(version)/IosevkaSS08-Regular.ttc
	$(info [$(name)] Installing fonts...)
	@mkdir -p ~/.local/share/fonts
	@ln -fs $(abspath $(dir $<)) $@
	@fc-cache -vf >/dev/null

$(data_dir)/$(version)/IosevkaSS08-Regular.ttc: $(data_dir)/$(version)/iosevka.zip
	$(info [$(name)] Unzipping...)
	@unzip -d $(dir $@) $<
	@touch $@

$(data_dir)/$(version)/iosevka.zip:
	$(info [$(name)] Downloading archive...)
	@curl $(archive_url) --create-dirs -Lo $@
	@touch $@
