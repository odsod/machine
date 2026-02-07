name := jwt-cli
version := 6.2.0
archive_url := https://github.com/mike-engel/jwt-cli/releases/download/$(version)/jwt-linux.tar.gz
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: ~/.local/bin/jwt
~/.local/bin/jwt: $(data_dir)/$(version)/jwt
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

$(data_dir)/$(version)/jwt: $(data_dir)/$(version)/archive.tar.gz
	$(info [$(name)] Extracting archive...)
	@tar -C $(dir $<) -xf $<
	@touch $@
	@chmod +x $@

$(data_dir)/$(version)/archive.tar.gz:
	$(info [$(name)] Downloading archive...)
	@curl $(archive_url) --create-dirs -Lo $@
	@touch $@
