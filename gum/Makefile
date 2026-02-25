name := gum
# Discovery: https://github.com/charmbracelet/gum/releases/latest
version := 0.17.0
archive_url := https://github.com/charmbracelet/gum/releases/download/v$(version)/gum_$(version)_Linux_x86_64.tar.gz
archive_dir := gum_$(version)_Linux_x86_64
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: install
install: ~/.local/bin/$(name) ~/.local/share/man/man1/$(name).1

.PHONY: ~/.local/bin/$(name)
~/.local/bin/$(name): $(data_dir)/$(version)/$(archive_dir)/gum
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

~/.local/share/man/man1/$(name).1: ~/.local/bin/$(name)
	$(info [$(name)] Writing man page $@...)
	@mkdir -p $(dir $@)
	@$(abspath $<) man > $@

$(data_dir)/$(version)/$(archive_dir)/gum: $(data_dir)/$(version)/archive.tar.gz
	$(info [$(name)] Extracting $<...)
	@tar -C $(dir $<) -xf $<
	@touch $@
	@chmod +x $@

$(data_dir)/$(version)/archive.tar.gz:
	$(info [$(name)] Downloading $(archive_url)...)
	@curl -L $(archive_url) --create-dirs -o $@
	@touch $@
