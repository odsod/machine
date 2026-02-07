name := gemini-cli

.PHONY: all
all: \
	~/.config/gemini/settings.json \
	~/.local/share/npm/bin/gemini

.PHONY: ~/.config/gemini/settings.json
~/.config/gemini/settings.json: settings.json
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

~/.local/share/npm/bin/gemini:
	@npm install -g @google/gemini-cli
