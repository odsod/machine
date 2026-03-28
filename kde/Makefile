name := kde

.PHONY: install
install: \
	~/.config/mimeapps.list \
	enable-kwallet

.PHONY: enable-kwallet
# Enable KWallet and install PAM integration for automatic unlocking.
enable-kwallet:
	$(info [$(name)] Enabling KWallet...)
	@mkdir -p ~/.config
	@printf '%s\n' '[Wallet]' 'Enabled=true' 'First Use=false' > ~/.config/kwalletrc
	@sudo dnf install -y kwallet-pam

.PHONY: ~/.config/mimeapps.list
~/.config/mimeapps.list: mimeapps.list
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@
