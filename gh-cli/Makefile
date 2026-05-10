name := gh-cli
# Discovery: https://github.com/cli/cli/releases/latest
version := 2.92.0
archive_url := https://github.com/cli/cli/releases/download/v$(version)/gh_$(version)_linux_amd64.tar.gz
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: ~/.local/bin/gh
~/.local/bin/gh: $(data_dir)/$(version)/gh_$(version)_linux_amd64/bin/gh
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

$(data_dir)/$(version)/gh_$(version)_linux_amd64/bin/gh: $(data_dir)/$(version)/archive.tar.gz
	$(info [$(name)] Extracting $<...)
	@tar -C $(dir $<) -xf $<
	@touch $@
	@chmod +x $@

$(data_dir)/$(version)/archive.tar.gz:
	$(info [$(name)] Downloading $(archive_url)...)
	@curl $(archive_url) -fLo $@ --create-dirs
	@touch $@
