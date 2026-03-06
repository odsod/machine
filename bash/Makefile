name := bash

# Discovery: https://www.npmjs.com/package/bash-language-server
bashls_version := 5.6.0

# Discovery: https://github.com/koalaman/shellcheck/releases/latest
shellcheck_version := v0.11.0
shellcheck_archive := shellcheck-$(shellcheck_version).linux.x86_64.tar.xz
shellcheck_url := https://github.com/koalaman/shellcheck/releases/download/$(shellcheck_version)/$(shellcheck_archive)

# Discovery: https://github.com/mvdan/sh/releases/latest
shfmt_version := v3.12.0
shfmt_binary := shfmt_$(shfmt_version)_linux_amd64
shfmt_url := https://github.com/mvdan/sh/releases/download/$(shfmt_version)/$(shfmt_binary)

data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: all
all: npm-packages \
	~/.local/bin/shellcheck \
	~/.local/bin/shfmt

.PHONY: npm-packages
npm-packages:
	$(info [$(name)] Installing bash-language-server...)
	@$(MAKE) -C ../nodejs ~/.local/bin/npm
	@~/.local/bin/npm install -g bash-language-server@$(bashls_version)

.PHONY: ~/.local/bin/shellcheck
~/.local/bin/shellcheck: $(data_dir)/shellcheck/$(shellcheck_version)/shellcheck
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

$(data_dir)/shellcheck/$(shellcheck_version)/shellcheck: $(data_dir)/shellcheck/$(shellcheck_version)/archive.tar.xz
	$(info [$(name)] Extracting $(shellcheck_archive)...)
	@tar -C $(dir $<) -xf $<
	@mv -f $(dir $<)shellcheck-$(shellcheck_version)/shellcheck $@
	@chmod +x $@

$(data_dir)/shellcheck/$(shellcheck_version)/archive.tar.xz:
	$(info [$(name)] Downloading $(shellcheck_url)...)
	@curl -L $(shellcheck_url) --create-dirs -o $@

.PHONY: ~/.local/bin/shfmt
~/.local/bin/shfmt: $(data_dir)/shfmt/$(shfmt_version)/shfmt
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

$(data_dir)/shfmt/$(shfmt_version)/shfmt:
	$(info [$(name)] Downloading $(shfmt_url)...)
	@curl -L $(shfmt_url) --create-dirs -o $@
	@chmod +x $@
