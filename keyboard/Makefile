.PHONY: install
install: \
	install-symbols \
	install-evdev

install-symbols: /usr/share/X11/xkb/symbols/odsod

.PHONY: install-evdev
install-evdev: /usr/share/X11/xkb/rules/evdev.xml
	@grep -q odsod $< || sudo sed -i 's#</layoutList>#<layout><configItem><name>odsod</name><languageList><iso639Id>eng</iso639Id></languageList></configItem></layout></layoutList>#' $<

/usr/share/X11/xkb/symbols/odsod: odsod
	sudo cp $< $@
