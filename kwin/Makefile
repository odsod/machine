.PHONY: install
install: \
	install-package \
	/usr/share/dbus-1/services/io.github.odsod.kwin.service \
	/usr/local/bin/odsod-kwin-dbus-service.py

.PHONY: install-package
install-package:
	kpackagetool5 -i .

.PHONY: install-deps
install-deps:
	sudo pip install PySide2

.PHONY: upgrade-package
upgrade-package:
	kpackagetool5 -u .

.PHONY: uninstall-package
uninstall-package:
	kpackagetool5 -r .

.PHONY: develop-package
develop-package:
	qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.showInteractiveKWinConsole

/usr/share/dbus-1/services/io.github.odsod.kwin.service: io.github.odsod.kwin.service
	sudo cp -f $< $@

/usr/local/bin/odsod-kwin-dbus-service.py: odsod-kwin-dbus-service.py
	sudo cp -f $< $@
