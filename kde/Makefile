name := kde

.PHONY: install
install: \
	~/.config/mimeapps.list \
	~/.config/fontconfig/fonts.conf \
	configure-fonts \
	enable-kwallet

~/.config/fontconfig/fonts.conf: fonts.conf
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: configure-fonts
configure-fonts:
	$(info [$(name)] Configuring fonts...)
	@kwriteconfig6 --group "General" --key "font" "Inter,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
	@kwriteconfig6 --group "General" --key "fixed" "Iosevka SS08,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
	@kwriteconfig6 --group "General" --key "smallestReadableFont" "Inter,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
	@kwriteconfig6 --group "General" --key "toolBarFont" "Inter,9,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
	@kwriteconfig6 --group "General" --key "menuFont" "Inter,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
	@kwriteconfig6 --group "General" --key "XftAntialias" "true"
	@kwriteconfig6 --group "General" --key "XftHintStyle" "hintslight"
	@kwriteconfig6 --group "General" --key "XftSubPixel" "none"
	@kwriteconfig6 --group "WM" --key "activeFont" "Inter,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"

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
