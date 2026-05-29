name := jwt-cli
# Discovery: https://github.com/mike-engel/jwt-cli/releases/latest
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

.PHONY: discover
discover:
	@printf 'version=%s\n' "$$(curl -sI https://github.com/mike-engel/jwt-cli/releases/latest \
		| grep -i ^location: | grep -oP '/\K[0-9][0-9a-z.-]+' || echo UNKNOWN)"
