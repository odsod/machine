name := kwin

.PHONY: install
install: \
	install-package \
	enable-plugin \
	~/.local/share/dbus-1/services/io.github.odsod.kwin.service \
	~/.local/bin/odsod-kwin-dbus-service.py

.PHONY: enable-plugin
enable-plugin:
	$(info [$(name)] Enabling Plasma plugin...)
	@kwriteconfig6 --file kwinrc --group Plugins --key odsodEnabled false
	@sleep 1
	@kwriteconfig6 --file kwinrc --group Plugins --key odsodEnabled true

.PHONY: install-package
install-package:
	$(info [$(name)] Installing Plasma package...)
	@kpackagetool6 --type=KWin/Script --install . 2>/dev/null || kpackagetool6 --type=KWin/Script --upgrade .

.PHONY: uninstall-package
uninstall-package:
	$(info [$(name)] Uninstalling Plasma package...)
	@kpackagetool6 --type=KWin/Script --remove odsod

.PHONY: develop-package
develop-package:
	$(info [$(name)] Developing package...)
	@qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.showInteractiveKWinConsole

~/.local/share/dbus-1/services/io.github.odsod.kwin.service: io.github.odsod.kwin.service
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

~/.local/bin/odsod-kwin-dbus-service.py: odsod-kwin-dbus-service.py
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: tail
tail:
	$(info [$(name)] Tailing log...)
	@journalctl --user -f -t odsod-kwin-dbus-service
