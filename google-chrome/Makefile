name := google-chrome

.PHONY: install
install: install-packages ~/.local/bin/google-chrome ~/.config/chrome-flags.conf

.PHONY: install-packages
install-packages:
	$(info [$(name)] Installing packages...)
	@sudo dnf install -y fedora-workstation-repositories
	@sudo dnf config-manager setopt google-chrome.enabled=1
	@sudo dnf install -y google-chrome-stable

.PHONY: ~/.local/bin/google-chrome
~/.local/bin/google-chrome: google-chrome.sh
	$(info [$(name)] Installing wrapper $@...)
	@mkdir -p $(dir $@)
	@install -m 0755 $< $@

.PHONY: ~/.config/chrome-flags.conf
~/.config/chrome-flags.conf: chrome-flags.conf
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@
