name := antigravity
# Discovery: https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/linux_amd64.json
# Bump: update version and archive_url together from `make discover` output.
version := 1.0.12
archive_url := https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.12-6156052174077952/linux-x64/cli_linux_x64.tar.gz
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: all
all: \
	$(HOME)/.gemini/antigravity-cli/settings.json \
	$(HOME)/.gemini/policies/machine.toml \
	$(HOME)/.local/bin/agy

.PHONY: $(HOME)/.gemini/antigravity-cli/settings.json
$(HOME)/.gemini/antigravity-cli/settings.json: settings.json
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: $(HOME)/.gemini/policies/machine.toml
$(HOME)/.gemini/policies/machine.toml: policies.toml
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: $(HOME)/.local/bin/agy
$(HOME)/.local/bin/agy: $(data_dir)/$(version)/antigravity
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

$(data_dir)/$(version)/antigravity: $(data_dir)/$(version)/archive.tar.gz
	$(info [$(name)] Extracting $<...)
	@tar -C $(dir $<) -xf $< antigravity
	@chmod +x $@

$(data_dir)/$(version)/archive.tar.gz:
	$(info [$(name)] Downloading $(archive_url)...)
	@curl -fsSL $(archive_url) --create-dirs -Lo $@

.PHONY: discover
discover:
	@curl -fsSL \
		https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/linux_amd64.json \
		| jq -r '"version=\(.version // "UNKNOWN")", "archive_url=\(.url // "UNKNOWN")"'
