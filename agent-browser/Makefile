name := agent-browser
# Discovery: https://github.com/vercel-labs/agent-browser/releases/latest
version := 0.15.0
url := https://github.com/vercel-labs/agent-browser/releases/download/v$(version)/agent-browser-linux-x64
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: ~/.local/bin/$(name)
~/.local/bin/$(name): $(data_dir)/$(version)/$(name)
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

$(data_dir)/$(version)/$(name):
	$(info [$(name)] Downloading $(url)...)
	@curl -L $(url) --create-dirs -o $@
	@chmod +x $@
