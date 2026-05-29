name := iosevka
# Discovery: https://github.com/be5invis/Iosevka/releases/latest
version := 34.6.1
archive_url := https://github.com/be5invis/Iosevka/releases/download/v$(version)/PkgTTC-IosevkaSS08-$(version).zip
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: ~/.local/share/fonts/iosevka
~/.local/share/fonts/iosevka: $(data_dir)/$(version)/IosevkaSS08-Regular.ttc
	$(info [$(name)] Installing fonts...)
	@mkdir -p ~/.local/share/fonts
	@ln -fsT $(abspath $(dir $<)) $@
	@fc-cache -vf >/dev/null

$(data_dir)/$(version)/IosevkaSS08-Regular.ttc: $(data_dir)/$(version)/iosevka.zip
	$(info [$(name)] Unzipping...)
	@unzip -d $(dir $@) $<
	@touch $@

$(data_dir)/$(version)/iosevka.zip:
	$(info [$(name)] Downloading archive...)
	@curl $(archive_url) --create-dirs -Lo $@
	@touch $@

.PHONY: discover
discover:
	@printf 'version=%s\n' "$$(curl -sI https://github.com/be5invis/Iosevka/releases/latest \
		| grep -i ^location: | grep -oP '/v\K[0-9][0-9a-z.-]+' || echo UNKNOWN)"
