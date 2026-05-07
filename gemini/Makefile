name := gemini
# Discovery: https://registry.npmjs.org/@google/gemini-cli/latest
version := 0.41.2
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: all
all: \
	~/.gemini/settings.json \
	~/.gemini/hooks/rtk-hook-gemini.sh \
	~/.gemini/hooks/.rtk-hook.sha256 \
	~/.gemini/policies/machine.toml \
	~/.local/share/npm/bin/gemini

# Discovery: https://github.com/google-gemini/gemini-cli/issues/1825
# TODO: Move to ~/.config/gemini/settings.json when XDG support is improved
.PHONY: ~/.gemini/settings.json
~/.gemini/settings.json: settings.json
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.gemini/hooks/rtk-hook-gemini.sh
~/.gemini/hooks/rtk-hook-gemini.sh: hooks/rtk-hook-gemini.sh
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

~/.gemini/hooks/.rtk-hook.sha256: ~/.gemini/hooks/rtk-hook-gemini.sh
	$(info [$(name)] Writing $@...)
	@hash=$$(sha256sum "$<" | awk '{print $$1}'); \
		tmp=$@.tmp; \
		printf '%s  rtk-hook-gemini.sh\n' "$$hash" > "$$tmp"; \
		mv "$$tmp" $@; \
		chmod 0444 $@

.PHONY: ~/.gemini/policies/machine.toml
~/.gemini/policies/machine.toml: policies.toml
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

~/.local/share/npm/bin/gemini: $(data_dir)/$(version)/installed

$(data_dir)/$(version)/installed:
	@$(MAKE) -C ../nodejs ~/.local/bin/npm
	@~/.local/bin/npm install -g @google/gemini-cli@$(version)
	@mkdir -p $(dir $@)
	@touch $@
