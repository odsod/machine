name := go
version := 1.24.4
archive_url := https://go.dev/dl/go$(version).linux-amd64.tar.gz

.PHONY: all
all: \
	~/.local/share/odsod/machine/go \
	~/.config/environment.d/10-$(name).conf

.PHONY: ~/.config/environment.d/10-$(name).conf
~/.config/environment.d/10-$(name).conf: environment.conf
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.local/share/odsod/machine/go
~/.local/share/odsod/machine/go: build/$(version)/go
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: build/$(version)/go
build/$(version)/go: build/$(version)/go/bin/$(name)

build/$(version)/go/bin/$(name): build/$(version)/archive.tar.gz
	$(info [$(name)] Extracting $<...)
	@tar -C $(dir $<) -xf $<
	@touch $@
	@chmod +x $@

build/$(version)/archive.tar.gz:
	$(info [$(name)] Downloading $(archive_url)...)
	@curl $(archive_url) --create-dirs -Lo $@
	@touch $@
