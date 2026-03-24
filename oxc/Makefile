name := oxc
# Discovery: https://github.com/oxc-project/oxc/releases/latest
release_tag := apps_v1.57.0
# Discovery: https://www.npmjs.com/package/oxfmt
oxfmt_version := 0.42.0
# Discovery: https://github.com/oxc-project/oxc/releases?q=apps_v&expanded=true
oxlint_version := 1.57.0

oxlint_archive := oxlint-x86_64-unknown-linux-gnu.tar.gz
oxlint_extracted_binary := oxlint-x86_64-unknown-linux-gnu
oxlint_archive_url := https://github.com/oxc-project/oxc/releases/download/$(release_tag)/$(oxlint_archive)

data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)
oxfmt_npm_bin := $(HOME)/.local/share/npm/bin/oxfmt

.PHONY: install
install: \
	~/.local/bin/oxfmt \
	~/.local/bin/oxlint

.PHONY: ~/.local/bin/oxfmt
~/.local/bin/oxfmt: $(data_dir)/oxfmt/$(oxfmt_version)/installed
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(oxfmt_npm_bin) $@

.PHONY: ~/.local/bin/oxlint
~/.local/bin/oxlint: $(data_dir)/oxlint/$(oxlint_version)/oxlint
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

$(data_dir)/oxfmt/$(oxfmt_version)/installed:
	$(info [$(name)] Installing oxfmt@$(oxfmt_version) with npm...)
	@$(MAKE) -C ../nodejs ~/.local/bin/npm
	@~/.local/bin/npm install -g oxfmt@$(oxfmt_version)
	@mkdir -p $(dir $@)
	@touch $@

$(data_dir)/oxlint/$(oxlint_version)/oxlint: $(data_dir)/oxlint/$(oxlint_version)/archive.tar.gz
	$(info [$(name)] Extracting $(oxlint_archive)...)
	@tar -C $(dir $<) -xf $<
	@mv -f $(dir $<)$(oxlint_extracted_binary) $@
	@chmod +x $@

$(data_dir)/oxlint/$(oxlint_version)/archive.tar.gz:
	$(info [$(name)] Downloading $(oxlint_archive_url)...)
	@curl -L $(oxlint_archive_url) --create-dirs -o $@
