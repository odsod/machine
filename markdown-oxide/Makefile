name := markdown-oxide
# Discovery: https://github.com/Feel-ix-343/markdown-oxide/releases/latest
version := 0.25.10
archive_url := https://github.com/Feel-ix-343/markdown-oxide/releases/download/v$(version)/markdown-oxide-v$(version)-x86_64-unknown-linux-gnu.tar.gz
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: all
all: ~/.local/bin/$(name)

.PHONY: ~/.local/bin/$(name)
~/.local/bin/$(name): $(data_dir)/$(version)/$(name)
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

$(data_dir)/$(version)/$(name): $(data_dir)/$(version)/archive.tar.gz
	$(info [$(name)] Extracting archive...)
	@tar -C $(dir $<) -xzf $< --strip-components=1
	@chmod +x $@
	@touch $@

$(data_dir)/$(version)/archive.tar.gz:
	$(info [$(name)] Downloading archive...)
	@curl -sL $(archive_url) --create-dirs -o $@
	@touch $@
