name := spacelift
# Discovery: https://github.com/spacelift-io/spacectl/releases/latest
version := 1.20.1
archive_url := https://github.com/spacelift-io/spacectl/releases/download/v$(version)/spacectl_$(version)_linux_amd64.zip
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: ~/.local/bin/spacectl
~/.local/bin/spacectl: $(data_dir)/$(version)/spacectl
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

$(data_dir)/$(version)/spacectl: $(data_dir)/$(version)/archive.zip
	$(info [$(name)] Extracting archive...)
	@unzip -q -o $< -d $(dir $@)
	@chmod +x $@
	@touch $@

$(data_dir)/$(version)/archive.zip:
	$(info [$(name)] Downloading archive...)
	@curl -sL $(archive_url) --create-dirs -o $@
	@touch $@
