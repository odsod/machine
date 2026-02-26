name := kde

.PHONY: install
install: \
	~/.config/mimeapps.list \
	disable-kwallet

.PHONY: disable-kwallet
# Disable KWallet, remove PAM integration, and delete existing wallets.
disable-kwallet:
	$(info [$(name)] Disabling KWallet...)
	@mkdir -p ~/.config
	@printf '%s\n' '[Wallet]' 'Enabled=false' 'First Use=false' > ~/.config/kwalletrc
	@sudo dnf remove -y kwallet-pam
	@rm -f ~/.local/share/kwalletd/*.kwallet ~/.local/share/kwalletd/*.kwl

.PHONY: ~/.config/mimeapps.list
~/.config/mimeapps.list: mimeapps.list
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@
