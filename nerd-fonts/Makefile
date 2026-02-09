name := nerd-fonts
# Discovery: https://github.com/ryanoasis/nerd-fonts/releases/latest
version := 3.4.0
archive_url := https://github.com/ryanoasis/nerd-fonts/releases/download/v$(version)/IosevkaTerm.zip
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: ~/.local/share/fonts/nerd-fonts
~/.local/share/fonts/nerd-fonts: $(data_dir)/$(version)/IosevkaTermNerdFont-Regular.ttf
	$(info [$(name)] Installing fonts...)
	@mkdir -p ~/.local/share/fonts
	@ln -fsT $(abspath $(dir $<)) $@
	@fc-cache -vf >/dev/null

$(data_dir)/$(version)/IosevkaTermNerdFont-Regular.ttf: $(data_dir)/$(version)/font.zip
	$(info [$(name)] Unzipping...)
	@unzip -o -d $(dir $@) $<
	@touch $@

$(data_dir)/$(version)/font.zip:
	$(info [$(name)] Downloading archive...)
	@curl -L $(archive_url) --create-dirs -o $@
	@touch $@
