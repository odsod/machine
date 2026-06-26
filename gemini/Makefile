name := gemini
# Discovery: https://registry.npmjs.org/@google/gemini-cli/latest
version := 0.49.0
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)
npm_bin := $(HOME)/.local/share/npm/bin/$(name)

.PHONY: all
all: \
	$(HOME)/.gemini/settings.json \
	remove-rtk-hook \
	$(HOME)/.gemini/policies/machine.toml \
	$(HOME)/.local/bin/$(name)

.PHONY: $(HOME)/.gemini/settings.json
$(HOME)/.gemini/settings.json: settings.json
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: remove-rtk-hook
remove-rtk-hook:
	$(info [$(name)] Removing stale rtk hook...)
	@rm -f \
		$(HOME)/.gemini/hooks/rtk-hook-gemini.sh \
		$(HOME)/.gemini/hooks/.rtk-hook.sha256

.PHONY: $(HOME)/.gemini/policies/machine.toml
$(HOME)/.gemini/policies/machine.toml: policies.toml
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: $(HOME)/.local/bin/$(name)
$(HOME)/.local/bin/$(name): $(data_dir)/$(version)/installed
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(npm_bin) $@

$(data_dir)/$(version)/installed:
	$(info [$(name)] Installing @google/gemini-cli@$(version) with npm...)
	@$(MAKE) -C ../nodejs ~/.local/bin/npm
	@~/.local/bin/npm install -g @google/gemini-cli@$(version)
	@mkdir -p $(dir $@)
	@touch $@

.PHONY: discover
discover:
	@printf 'version=%s\n' "$$(npm view @google/gemini-cli version)"
