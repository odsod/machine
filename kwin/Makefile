name := kwin

.PHONY: install
install: \
	install-deps \
	install-package \
	enable-plugin \
	/usr/share/dbus-1/services/io.github.odsod.kwin.service \
	/usr/local/bin/odsod-kwin-dbus-service.py

.PHONY: enable-plugin
enable-plugin:
	$(info [$(name)] Enabling Plasma plugin...)
	@kwriteconfig5 --file kwinrc --group Plugins --key odsodEnabled false
	@kwriteconfig5 --file kwinrc --group Plugins --key odsodEnabled true

.PHONY: install-package
install-package:
	$(info [$(name)] Installing Plasma package...)
	@kpackagetool5 -l | tail +2 | grep -q odsod && kpackagetool5 -u . || kpackagetool5 -i . \
		| sed -e "s/^/[$(name):$@] /"

.PHONY: install-deps
install-deps:
	$(info [$(name)] Installing deps...)
	@sudo apt-get install -y \
		python3-pyside2.qtgui \
		| sed -e "s/^/[$(name):$@] /"

.PHONY: develop-package
develop-package:
	$(info [$(name)] Developing package...)
	@qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.showInteractiveKWinConsole

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
