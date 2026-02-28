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
