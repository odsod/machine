name := encore
# https://encore.dev/api/releases?target=linux_amd64
version := 1.54.0
archive_url := https://d2f391esomvqpi.cloudfront.net/encore-$(version)-linux_amd64.tar.gz
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: all
all: \
	~/.local/share/odsod/machine/encore \
	~/.config/environment.d/10-$(name).conf

.PHONY: ~/.config/environment.d/10-$(name).conf
~/.config/environment.d/10-$(name).conf: environment.conf
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.local/share/odsod/machine/encore
~/.local/share/odsod/machine/encore: $(data_dir)/$(version)/bin/$(name)
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $(data_dir)/$(version)) $@

$(data_dir)/$(version)/bin/$(name): $(data_dir)/$(version)/archive.tar.gz
	$(info [$(name)] Extracting $<...)
	@tar -C $(dir $<) -xf $<
	@touch $@
	@chmod +x $@

$(data_dir)/$(version)/archive.tar.gz:
	$(info [$(name)] Downloading $(archive_url)...)
	@curl $(archive_url) --create-dirs -Lo $@
	@touch $@
