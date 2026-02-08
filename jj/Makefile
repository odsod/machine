name := jj
# Discovery: https://github.com/jj-vcs/jj/releases/latest
version := 0.38.0
archive_url := https://github.com/jj-vcs/jj/releases/download/v$(version)/jj-v$(version)-x86_64-unknown-linux-musl.tar.gz
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: ~/.local/bin/$(name)
~/.local/bin/$(name): $(data_dir)/$(version)/jj ~/.config/jj/config.toml
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.config/jj/config.toml
~/.config/jj/config.toml: config.toml
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

$(data_dir)/$(version)/jj: $(data_dir)/$(version)/archive.tar.gz
	$(info [$(name)] Extracting $<...)
	@tar -C $(dir $<) -xf $<
	@touch $@
	@chmod +x $@

$(data_dir)/$(version)/archive.tar.gz:
	$(info [$(name)] Downloading $(archive_url)...)
	@curl $(archive_url) --create-dirs -Lo $@
	@touch $@
