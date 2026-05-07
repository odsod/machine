name := go
# Discovery: https://go.dev/VERSION?m=text
version := 1.26.3
archive_url := https://go.dev/dl/go$(version).linux-amd64.tar.gz

# Discovery: https://github.com/golang/tools/releases (tags: gopls/v*)
gopls_version := v0.21.1
# Discovery: https://github.com/dominikh/go-tools/releases
staticcheck_version := 2026.1
# Discovery: https://github.com/mvdan/gofumpt/releases
gofumpt_version := v0.10.0

data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: all
all: \
	~/.local/share/odsod/machine/go \
	tools

.PHONY: tools
tools: ~/.local/share/odsod/machine/go
	$(info [$(name)] Installing tools...)
	@~/.local/share/odsod/machine/go/bin/go install golang.org/x/tools/gopls@$(gopls_version)
	@~/.local/share/odsod/machine/go/bin/go install honnef.co/go/tools/cmd/staticcheck@$(staticcheck_version)
	@~/.local/share/odsod/machine/go/bin/go install mvdan.cc/gofumpt@$(gofumpt_version)

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
