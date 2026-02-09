name := inter
# Discovery: https://github.com/rsms/inter/releases/latest
version := 4.1
archive_url := https://github.com/rsms/inter/releases/download/v$(version)/Inter-$(version).zip
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: ~/.local/share/fonts/inter.ttc
~/.local/share/fonts/inter.ttc: $(data_dir)/$(version)/Inter.ttc
	$(info [$(name)] Installing...)
	@mkdir -p ~/.local/share/fonts
	@ln -fsT $(abspath $<) $@
	@fc-cache -vf >/dev/null

$(data_dir)/$(version)/Inter.ttc: $(data_dir)/$(version)/archive.zip
	$(info [$(name)] Unzipping $<...)
	@unzip $< -d $(dir $@)
	@touch $@

$(data_dir)/$(version)/archive.zip:
	$(info [$(name)] Downloading $(archive_url)...)
	@curl $(archive_url) --create-dirs -Lo $@
	@touch $@
