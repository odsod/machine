name := smug
# Discovery: https://api.github.com/repos/ivaaaan/smug/releases/latest
version := 0.3.17

archive := smug_$(version)_Linux_x86_64.tar.gz
archive_url := https://github.com/ivaaaan/smug/releases/download/v$(version)/$(archive)

data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: install
install: ~/.local/bin/smug

.PHONY: ~/.local/bin/smug
~/.local/bin/smug: $(data_dir)/$(version)/smug
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

$(data_dir)/$(version)/smug: $(data_dir)/$(version)/$(archive)
	$(info [$(name)] Extracting archive...)
	@tar -C $(dir $<) -xzf $< smug
	@touch $@
	@chmod +x $@

$(data_dir)/$(version)/$(archive):
	$(info [$(name)] Downloading archive...)
	@mkdir -p $(dir $@)
	@curl -sL $(archive_url) -o $@
