name := oxc
# Discovery: https://github.com/oxc-project/oxc/releases/latest
# Structure: shared release_tag for downloads, per-tool versions for local paths.
release_tag := apps_v1.50.0
oxfmt_version := 0.35.0
oxlint_version := 1.50.0

oxfmt_archive := oxfmt-x86_64-unknown-linux-gnu.tar.gz
oxfmt_extracted_binary := oxfmt-x86_64-unknown-linux-gnu
oxfmt_archive_url := https://github.com/oxc-project/oxc/releases/download/$(release_tag)/$(oxfmt_archive)

oxlint_archive := oxlint-x86_64-unknown-linux-gnu.tar.gz
oxlint_extracted_binary := oxlint-x86_64-unknown-linux-gnu
oxlint_archive_url := https://github.com/oxc-project/oxc/releases/download/$(release_tag)/$(oxlint_archive)

data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: install
install: \
	~/.local/bin/oxfmt \
	~/.local/bin/oxlint

.PHONY: ~/.local/bin/oxfmt
~/.local/bin/oxfmt: $(data_dir)/oxfmt/$(oxfmt_version)/oxfmt
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.local/bin/oxlint
~/.local/bin/oxlint: $(data_dir)/oxlint/$(oxlint_version)/oxlint
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

$(data_dir)/oxfmt/$(oxfmt_version)/oxfmt: $(data_dir)/oxfmt/$(oxfmt_version)/archive.tar.gz
	$(info [$(name)] Extracting $(oxfmt_archive)...)
	@tar -C $(dir $<) -xf $<
	@mv -f $(dir $<)$(oxfmt_extracted_binary) $@
	@chmod +x $@

$(data_dir)/oxlint/$(oxlint_version)/oxlint: $(data_dir)/oxlint/$(oxlint_version)/archive.tar.gz
	$(info [$(name)] Extracting $(oxlint_archive)...)
	@tar -C $(dir $<) -xf $<
	@mv -f $(dir $<)$(oxlint_extracted_binary) $@
	@chmod +x $@

$(data_dir)/oxfmt/$(oxfmt_version)/archive.tar.gz:
	$(info [$(name)] Downloading $(oxfmt_archive_url)...)
	@curl -L $(oxfmt_archive_url) --create-dirs -o $@

$(data_dir)/oxlint/$(oxlint_version)/archive.tar.gz:
	$(info [$(name)] Downloading $(oxlint_archive_url)...)
	@curl -L $(oxlint_archive_url) --create-dirs -o $@
