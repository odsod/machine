name := jetbrains-toolbox
# Discovery: https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release
version := 3.2.0.65851
archive_url := https://download.jetbrains.com/toolbox/jetbrains-toolbox-$(version).tar.gz
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: ~/.local/bin/jetbrains-toolbox
~/.local/bin/jetbrains-toolbox: $(data_dir)/$(version)/jetbrains-toolbox-$(version)/jetbrains-toolbox
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

$(data_dir)/$(version)/jetbrains-toolbox-$(version)/jetbrains-toolbox: $(data_dir)/$(version)/archive.tar.gz
	$(info [$(name)] Extracting archive...)
	@tar -C $(dir $<) -xf $<
	@touch $@
	@chmod +x $@

$(data_dir)/$(version)/archive.tar.gz:
	$(info [$(name)] Downloading archive...)
	@curl $(archive_url) --create-dirs -Lo $@
	@touch $@
