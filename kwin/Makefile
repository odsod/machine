name := kwin

.PHONY: install
install: \
	install-deps \
	install-package \
	enable-plugin \
	~/.config/kwinrulesrc \
	/usr/share/dbus-1/services/io.github.odsod.kwin.service \
	/usr/local/bin/odsod-kwin-dbus-service.py

.PHONY: enable-plugin
enable-plugin:
	$(info [$(name)] Enabling Plasma plugin...)
	@kwriteconfig5 --file kwinrc --group Plugins --key odsodEnabled false
	@sleep 1
	@kwriteconfig5 --file kwinrc --group Plugins --key odsodEnabled true

.PHONY: install-package
install-package:
	$(info [$(name)] Installing Plasma package...)
	@kpackagetool6 --type=KWin/Script --install .

.PHONY: uninstall-package
uninstall-package:
	$(info [$(name)] Uninstalling Plasma package...)
	@kpackagetool6 --type=KWin/Script --remove odsod

.PHONY: install-deps
install-deps:
	$(info [$(name)] Installing deps...)
	@sudo dnf install -y python3-pyside6

.PHONY: develop-package
develop-package:
	$(info [$(name)] Developing package...)
	@qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.showInteractiveKWinConsole

.PHONY: ~/.config/kwinrulesrc
~/.config/kwinrulesrc: kwinrulesrc
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

/usr/share/dbus-1/services/io.github.odsod.kwin.service: io.github.odsod.kwin.service
	$(info [$(name)] Copying $@...)
	@sudo cp -f $< $@

/usr/local/bin/odsod-kwin-dbus-service.py: odsod-kwin-dbus-service.py
	$(info [$(name)] Copying $@...)
	@sudo cp -f $< $@

.PHONY: tail-dbus
tail-dbus: ~/.local/share/sddm/wayland-session.log
	$(info [$(name)] Tailing $<...)
	@tail -f $<

.PHONY: tail-kwin
tail-kwin:
	$(info [$(name)] Tailing KWin log...)
	@journalctl -f
