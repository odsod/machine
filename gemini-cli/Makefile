name := gemini-cli

# Discovery: https://github.com/gemini-cli-extensions/workspace/releases
workspace_extension_version := 0.0.5

.PHONY: all
all: \
	~/.gemini/settings.json \
	~/.local/share/npm/bin/gemini

# Discovery: https://github.com/google-gemini/gemini-cli/issues/1825
# TODO: Move to ~/.config/gemini/settings.json when XDG support is improved
.PHONY: ~/.gemini/settings.json
~/.gemini/settings.json: settings.json
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

~/.local/share/npm/bin/gemini:
	@npm install -g @google/gemini-cli

.PHONY: workspace-extension
workspace-extension: ~/.local/share/npm/bin/gemini
	$(info [$(name)] Installing workspace extension v$(workspace_extension_version)...)
	@mkdir -p $(HOME)/Code/github.com/gemini-cli-extensions
	@test -d $(HOME)/Code/github.com/gemini-cli-extensions/workspace || \
		git clone https://github.com/gemini-cli-extensions/workspace \
		$(HOME)/Code/github.com/gemini-cli-extensions/workspace
	@cd $(HOME)/Code/github.com/gemini-cli-extensions/workspace && \
		git fetch --tags && \
		git checkout v$(workspace_extension_version) && \
		npm ci && \
		npm run build
	@gemini extensions list 2>&1 | grep -F "Source: $(HOME)/Code/github.com/gemini-cli-extensions/workspace (Type: link)" >/dev/null || \
	(gemini extensions uninstall google-workspace >/dev/null 2>&1 || true; \
	cd $(HOME)/Code/github.com/gemini-cli-extensions/workspace && gemini extensions link .)
