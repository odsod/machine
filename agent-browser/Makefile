name := agent-browser
# Discovery: https://github.com/vercel-labs/agent-browser/releases/latest
version := 0.15.1
url := https://registry.npmjs.org/$(name)/-/$(name)-$(version).tgz
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)
active_dir := $(HOME)/.local/share/odsod/machine/$(name)
version_dir := $(data_dir)/$(version)
package_dir := $(version_dir)/package

.PHONY: ~/.local/bin/$(name)
~/.local/bin/$(name): $(name) ~/.config/$(name)/config.json $(active_dir)
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.config/$(name)/config.json
~/.config/$(name)/config.json: config.json
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

$(active_dir): $(package_dir)/dist/daemon.js
	$(info [$(name)] Activating version $(version)...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $(package_dir)) $@

$(package_dir)/dist/daemon.js: $(version_dir)/$(name)-$(version).tgz
	$(info [$(name)] Extracting $<...)
	@tar -C $(version_dir) -xzf $<
	@chmod +x $(package_dir)/bin/agent-browser-linux-x64

$(version_dir)/$(name)-$(version).tgz:
	$(info [$(name)] Downloading $(url)...)
	@curl -L $(url) --create-dirs -o $@

downloads_dir := $(active_dir)/downloads
personal_prefs := $(active_dir)/profiles/personal_profile_data/Default/Preferences
work_prefs    := $(active_dir)/profiles/work_profile_data/Default/Preferences

.PHONY: configure-profiles
configure-profiles:
	@mkdir -p $(downloads_dir)
	@tmp=$$(mktemp) && \
	 jq '.download += {"default_directory": "$(downloads_dir)", "prompt_for_download": false, "directory_upgrade": true}' \
	   $(personal_prefs) > "$$tmp" && mv "$$tmp" $(personal_prefs)
	@tmp=$$(mktemp) && \
	 jq '.download += {"default_directory": "$(downloads_dir)", "prompt_for_download": false, "directory_upgrade": true}' \
	   $(work_prefs) > "$$tmp" && mv "$$tmp" $(work_prefs)
