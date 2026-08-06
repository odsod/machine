name := herdr
# Discovery: https://github.com/herdrdev/herdr/releases/latest
version := 0.8.0
binary_url := https://github.com/herdrdev/herdr/releases/download/v$(version)/herdr-linux-x86_64

data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)/$(version)

.PHONY: install
install: ~/.local/bin/$(name) ~/.config/$(name)/config.toml ~/.local/bin/start-workspace ~/.local/bin/recorder-toggle-herdr ~/.config/ghostty/ghostty-herdr.sh

.PHONY: ~/.local/bin/$(name)
~/.local/bin/$(name): $(data_dir)/$(name)
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.config/$(name)/config.toml
~/.config/$(name)/config.toml: config.toml
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.local/bin/start-workspace
~/.local/bin/start-workspace: start-workspace
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.local/bin/recorder-toggle-herdr
~/.local/bin/recorder-toggle-herdr: recorder-toggle
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.config/ghostty/ghostty-herdr.sh
~/.config/ghostty/ghostty-herdr.sh: ../ghostty/ghostty-herdr.sh
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

$(data_dir)/$(name):
	$(info [$(name)] Downloading $(binary_url)...)
	@curl -fsSL "$(binary_url)" --create-dirs -o "$@"
	@chmod +x "$@"

.PHONY: discover
discover:
	@printf 'version=%s\n' "$$(curl -sI https://github.com/herdrdev/herdr/releases/latest \
		| grep -i ^location: | grep -oP '/v\K[0-9][0-9a-z.-]+' || echo UNKNOWN)"
