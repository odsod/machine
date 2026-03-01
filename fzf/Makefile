name := fzf
# Discovery: https://github.com/junegunn/fzf/releases/latest
version := 0.68.0
archive_url := https://github.com/junegunn/fzf/releases/download/v$(version)/fzf-$(version)-linux_amd64.tar.gz
manpage_url := https://raw.githubusercontent.com/junegunn/fzf/refs/tags/v$(version)/man/man1/fzf.1
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)
manpage_data_path := $(data_dir)/$(version)/fzf.1

.PHONY: install
install: ~/.local/bin/$(name) ~/.local/share/man/man1/fzf.1

.PHONY: ~/.local/bin/$(name)
~/.local/bin/$(name): $(data_dir)/$(version)/$(name)
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.local/share/man/man1/fzf.1
~/.local/share/man/man1/fzf.1: $(manpage_data_path)
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

$(data_dir)/$(version)/$(name): $(data_dir)/$(version)/archive.tar.gz
	$(info [$(name)] Extracting $<...)
	@tar -C $(dir $<) -xf $<
	@touch $@
	@chmod +x $@

$(data_dir)/$(version)/archive.tar.gz:
	$(info [$(name)] Downloading $(archive_url)...)
	@curl -L $(archive_url) --create-dirs -o $@

$(manpage_data_path):
	$(info [$(name)] Downloading $(manpage_url)...)
	@curl -L $(manpage_url) --create-dirs -o $@
