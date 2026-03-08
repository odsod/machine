name := gemini


.PHONY: all
all: \
	~/.gemini/settings.json \
	~/.gemini/policies/machine.toml \
	~/.local/share/npm/bin/gemini

# Discovery: https://github.com/google-gemini/gemini-cli/issues/1825
# TODO: Move to ~/.config/gemini/settings.json when XDG support is improved
.PHONY: ~/.gemini/settings.json
~/.gemini/settings.json: settings.json
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@


.PHONY: ~/.gemini/policies/machine.toml
~/.gemini/policies/machine.toml: policies.toml
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

~/.local/share/npm/bin/gemini:
	@$(MAKE) -C ../nodejs ~/.local/bin/npm
	@~/.local/bin/npm install -g @google/gemini-cli

