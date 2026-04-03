name := qbittorrent-cli
# Discovery: https://github.com/ludviglundgren/qbittorrent-cli/releases/latest
version := 2.2.0
archive_url := https://github.com/ludviglundgren/qbittorrent-cli/releases/download/v$(version)/qbittorrent-cli_$(version)_linux_amd64.tar.gz
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: ~/.local/bin/qbt
~/.local/bin/qbt: $(data_dir)/$(version)/qbt
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

$(data_dir)/$(version)/qbt: $(data_dir)/$(version)/archive.tar.gz
	$(info [$(name)] Extracting $<...)
	@tar -C $(dir $<) -xf $<
	@touch $@
	@chmod +x $@

$(data_dir)/$(version)/archive.tar.gz:
	$(info [$(name)] Downloading $(archive_url)...)
	@curl $(archive_url) --create-dirs -Lo $@
	@touch $@
