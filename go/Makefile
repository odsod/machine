name := go
version := 1.21.6
archive_url := https://go.dev/dl/go$(version).linux-amd64.tar.gz
archive := build/$(version)/archive.tar.gz
cmd := build/$(version)/go/bin/$(name)
gopath := build/$(version)/go
symlink := ~/.local/share/odsod/machine/go
environment := ~/.config/environment.d/10-odsod-machine-$(name).conf

.PHONY: all
all: $(symlink) $(environment)

.PHONY: $(environment)
$(environment): environment.conf
	$(info [$(name)] symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: $(symlink)
$(symlink): $(gopath)
	$(info [$(name)] symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: $(gopath)
$(gopath): $(cmd)

$(cmd): $(archive)
	$(info [$(name)] extracting $(archive)...)
	@tar -C $(dir $<) -xf $<
	@touch $@
	@chmod +x $@

$(archive):
	$(info [$(name)] downloading $(archive_url)...)
	@curl $(archive_url) --create-dirs -Lo $@
	@touch $@