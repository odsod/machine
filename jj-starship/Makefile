name := jj-starship
# Discovery: https://api.github.com/repos/dmmulroy/jj-starship/releases/latest
version := 0.7.0

archive := jj-starship-x86_64-unknown-linux-gnu.tar.gz
archive_url := https://github.com/dmmulroy/jj-starship/releases/download/v$(version)/$(archive)

data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: install
install: ~/.local/bin/jj-starship

.PHONY: ~/.local/bin/jj-starship
~/.local/bin/jj-starship: $(data_dir)/$(version)/jj-starship
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

$(data_dir)/$(version)/jj-starship: $(data_dir)/$(version)/$(archive)
	$(info [$(name)] Extracting archive...)
	@tar -C $(dir $<) -xzf $< ./jj-starship --strip-components=1
	@touch $@
	@chmod +x $@

$(data_dir)/$(version)/$(archive):
	$(info [$(name)] Downloading archive...)
	@mkdir -p $(dir $@)
	@curl -sL $(archive_url) -o $@
