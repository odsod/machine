name := encore
version := 1.48.2
archive_url := https://d2f391esomvqpi.cloudfront.net/encore-$(version)-linux_amd64.tar.gz

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
~/.local/share/odsod/machine/encore: build/$(version)/bin/$(name)
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $</../..) $@

build/$(version)/bin/$(name): build/$(version)/archive.tar.gz
	$(info [$(name)] Extracting $<...)
	@tar -C $(dir $<) -xf $<
	@touch $@
	@chmod +x $@

build/$(version)/archive.tar.gz:
	$(info [$(name)] Downloading $(archive_url)...)
	@curl $(archive_url) --create-dirs -Lo $@
	@touch $@
