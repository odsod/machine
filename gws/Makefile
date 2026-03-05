name := gws
# Discovery: https://github.com/googleworkspace/cli/releases/latest
version := 0.3.5
archive := gws-x86_64-unknown-linux-gnu.tar.gz
archive_url := https://github.com/googleworkspace/cli/releases/download/v$(version)/$(archive)
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: all
all: \
	~/.local/bin/$(name)

.PHONY: ~/.local/bin/$(name)
~/.local/bin/$(name): $(data_dir)/$(version)/$(name)
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

$(data_dir)/$(version)/$(name): $(data_dir)/$(version)/$(archive) $(data_dir)/$(version)/$(archive).sha256
	$(info [$(name)] Verifying $(archive)...)
	@cd $(dir $<) && sha256sum -c $(archive).sha256
	$(info [$(name)] Extracting $(archive)...)
	@tar -C $(dir $<) -xzf $<
	@mv $(dir $<)/gws-x86_64-unknown-linux-gnu/$(name) $@
	@touch $@
	@chmod +x $@

$(data_dir)/$(version)/$(archive):
	$(info [$(name)] Downloading $(archive_url)...)
	@curl -fsSL $(archive_url) --create-dirs -o $@

$(data_dir)/$(version)/$(archive).sha256:
	$(info [$(name)] Downloading $(archive_url).sha256...)
	@curl -fsSL $(archive_url).sha256 --create-dirs -o $@
