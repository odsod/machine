.PHONY: install
install:
	kpackagetool5 -i .

.PHONY: upgrade
upgrade:
	kpackagetool5 -u .

.PHONY: uninstall
uninstall:
	kpackagetool5 -r .

.PHONY: develop
develop:
	qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.showInteractiveKWinConsole
