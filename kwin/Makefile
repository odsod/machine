.PHONY: install
install: \
	install-package \
	install-deps \
	/usr/share/dbus-1/services/io.github.odsod.kwin.service \
	/usr/local/bin/odsod-kwin-dbus-service.py

.PHONY: install-package
install-package:
	@kpackagetool5 -l | tail +2 | grep -q odsod && kpackagetool5 -u . || kpackagetool5 -i .

.PHONY: install-deps
install-deps:
	@sudo apt-get install -y python3-pyside2.qtgui

.PHONY: develop-package
develop-package:
	@qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.showInteractiveKWinConsole

/usr/share/dbus-1/services/io.github.odsod.kwin.service: io.github.odsod.kwin.service
	@sudo cp -f $< $@

/usr/local/bin/odsod-kwin-dbus-service.py: odsod-kwin-dbus-service.py
	@sudo cp -f $< $@

.PHONY: tail-dbus
tail-dbus:
	@tail -f ~/.local/share/sddm/wayland-session.log

.PHONY: tail-kwin
tail-kwin:
	@journalctl -f
