name := fish
# Discovery: https://github.com/fish-shell/fish-shell/releases/latest
version := 4.5.0
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)
version_dir := $(data_dir)/$(version)
archive := $(version_dir)/$(name)-$(version)-linux-x86_64.tar.xz
archive_url := https://github.com/fish-shell/fish-shell/releases/download/$(version)/$(name)-$(version)-linux-x86_64.tar.xz
fish_bin := $(version_dir)/$(name)
system_fish := /usr/local/bin/$(name)

.PHONY: install
install: \
	$(fish_bin) \
	~/.local/bin/fish \
	$(system_fish) \
	ensure-shell-registered \
	~/.config/fish/config.fish \
	~/.config/fish/conf.d/fzf.fish \
	change-shell \
	install-packages

.PHONY: ensure-shell-registered
ensure-shell-registered:
	$(info [$(name)] Ensuring $(system_fish) exists in /etc/shells...)
	@grep -qxF "$(system_fish)" /etc/shells || \
		printf '%s\n' "$(system_fish)" | sudo tee -a /etc/shells >/dev/null
	@current_shell="$$(getent passwd "$$USER" | cut -d: -f7)"; \
	grep -qxF "$$current_shell" /etc/shells || \
		printf '%s\n' "$$current_shell" | sudo tee -a /etc/shells >/dev/null

.PHONY: change-shell
change-shell: $(system_fish) ensure-shell-registered
	$(info [$(name)] Changing login shell...)
	@if [ "$$(getent passwd "$$USER" | cut -d: -f7)" != "$(system_fish)" ]; then \
		sudo -n chsh -s "$(system_fish)" "$$USER"; \
	fi

.PHONY: install-packages
install-packages:
	$(info [$(name)] Removing package...)
	@sudo dnf remove -y fish

$(archive):
	$(info [$(name)] Downloading $(archive_url)...)
	@curl -L $(archive_url) --create-dirs -o $@

$(fish_bin): $(archive)
	$(info [$(name)] Extracting $<...)
	@tar -C $(dir $@) -xJf $<
	@chmod +x $@

.PHONY: ~/.local/bin/fish
~/.local/bin/fish: $(fish_bin)
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: $(system_fish)
$(system_fish): $(fish_bin)
	$(info [$(name)] Installing $@...)
	@sudo install -m 0755 $(abspath $<) $@

.PHONY: ~/.config/fish/config.fish
~/.config/fish/config.fish: config.fish
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.config/fish/conf.d/fzf.fish
~/.config/fish/conf.d/fzf.fish:
	$(info [$(name)] Generating fzf init...)
	@mkdir -p $(dir $@)
	@fzf --fish > $@
