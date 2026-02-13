name := claude-code
# Discovery: https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/latest
# Reference: https://claude.ai/install.sh
version := 2.1.41
url := https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/$(version)/linux-x64/claude
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: ~/.local/bin/claude
~/.local/bin/claude: $(data_dir)/$(version)/claude
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

$(data_dir)/$(version)/claude:
	$(info [$(name)] Downloading $(url)...)
	@curl $(url) --create-dirs -Lo $@
	@chmod +x $@
