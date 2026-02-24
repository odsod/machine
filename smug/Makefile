name := smug
# Discovery: https://api.github.com/repos/ivaaaan/smug/releases/latest
version := 0.3.17

archive := smug_$(version)_Linux_x86_64.tar.gz
archive_url := https://github.com/ivaaaan/smug/releases/download/v$(version)/$(archive)
man_url := https://raw.githubusercontent.com/ivaaaan/smug/v$(version)/man/man1/smug.1
fish_completion_url := https://raw.githubusercontent.com/ivaaaan/smug/v$(version)/completion/smug.fish

data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: install
install: \
	~/.local/bin/smug \
	~/.local/share/man/man1/smug.1 \
	~/.config/fish/completions/smug.fish \
	~/.config/smug

.PHONY: ~/.local/bin/smug
~/.local/bin/smug: $(data_dir)/$(version)/smug
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.local/share/man/man1/smug.1
~/.local/share/man/man1/smug.1: $(data_dir)/$(version)/smug.1
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.config/fish/completions/smug.fish
~/.config/fish/completions/smug.fish: $(data_dir)/$(version)/smug.fish
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

$(data_dir)/$(version)/smug.1:
	$(info [$(name)] Downloading manpage...)
	@mkdir -p $(dir $@)
	@curl -sL $(man_url) -o $@

$(data_dir)/$(version)/smug.fish:
	$(info [$(name)] Downloading fish completion...)
	@mkdir -p $(dir $@)
	@curl -sL $(fish_completion_url) -o $@

$(data_dir)/$(version)/smug: $(data_dir)/$(version)/$(archive)
	$(info [$(name)] Extracting archive...)
	@tar -C $(dir $<) -xzf $< smug
	@touch $@
	@chmod +x $@

$(data_dir)/$(version)/$(archive):
	$(info [$(name)] Downloading archive...)
	@mkdir -p $(dir $@)
	@curl -sL $(archive_url) -o $@

.PHONY: ~/.config/smug
~/.config/smug: sessions
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

sessions:
	$(info [$(name)] Cloning sessions repository...)
	@jj git clone git@github.com:odsod/sessions.git $@

