name := keyboard

.PHONY: install-evdev-rules
install-evdev-rules: /usr/share/X11/xkb/rules/evdev.xml
	$(info [$(name)] Installing evdev rules...)
	@grep -q odsod $< || sudo sed -i 's#</layoutList>#<layout><configItem><name>odsod</name><languageList><iso639Id>eng</iso639Id></languageList></configItem></layout></layoutList>#' $<

.PHONY: /usr/share/X11/xkb/symbols/odsod
/usr/share/X11/xkb/symbols/odsod: odsod
	$(info [$(name)] Copying $@...)
	@sudo cp $< $@
