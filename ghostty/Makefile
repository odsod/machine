name := ghostty

.PHONY: install-packages
install-packages: install-terra-repo ~/.config/ghostty/config ~/.config/ghostty/themes ~/.config/ghostty/ghostty-tmux.sh
	$(info [$(name)] Installing packages...)
	@sudo dnf install -y ghostty

.PHONY: install-terra-repo
install-terra-repo:
	$(info [$(name)] Installing Terra repo...)
	@rpm -q terra-release >/dev/null 2>&1 || \
		sudo dnf install -y --nogpgcheck \
			--repofrompath 'terra,https://repos.fyralabs.com/terra$$releasever' \
			terra-release

.PHONY: ~/.config/ghostty/config
~/.config/ghostty/config: config
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.config/ghostty/ghostty-tmux.sh
~/.config/ghostty/ghostty-tmux.sh: ghostty-tmux.sh
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.config/ghostty/themes
~/.config/ghostty/themes: themes
	$(info [$(name)] Symlinking $@...)
	@rm -rf $@
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@
