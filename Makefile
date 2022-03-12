.PHONY: install-deps
install-deps:
	sudo apt install keepassxc

.PHONY: dbus-install
dbus-install:
	make -C dbus install

.PHONY: kwin-install
kwin-install:
	make -C kwin install
