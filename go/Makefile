name := go
# Discovery: https://go.dev/VERSION?m=text
version := 1.26.0
archive_url := https://go.dev/dl/go$(version).linux-amd64.tar.gz
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: all
all: \
	~/.local/share/odsod/machine/go

.PHONY: ~/.local/share/odsod/machine/go
~/.local/share/odsod/machine/go: $(data_dir)/$(version)/go
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $(data_dir)/$(version)/go) $@

.PHONY: $(data_dir)/$(version)/go
$(data_dir)/$(version)/go: $(data_dir)/$(version)/go/bin/$(name)

$(data_dir)/$(version)/go/bin/$(name): $(data_dir)/$(version)/archive.tar.gz
	$(info [$(name)] Extracting $<...)
	@tar -C $(dir $<) -xf $<
	@touch $@
	@chmod +x $@

$(data_dir)/$(version)/archive.tar.gz:
	$(info [$(name)] Downloading $(archive_url)...)
	@curl $(archive_url) --create-dirs -Lo $@
	@touch $@
