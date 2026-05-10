name := webcam
script := c920-settings.sh
script_path := /usr/local/bin/$(script)
rules := 90-webcam-c920.rules
rules_path := /etc/udev/rules.d/$(rules)

.PHONY: install
install: install-packages $(script_path) $(rules_path)

.PHONY: install-packages
install-packages:
	$(info [$(name)] Installing packages...)
	@sudo dnf install -y v4l-utils

$(script_path): $(script)
	$(info [$(name)] Installing $@...)
	@sudo install -m 0755 $< $@

$(rules_path): $(rules)
	$(info [$(name)] Installing udev rule...)
	@sudo cp -f $< $@
	@sudo udevadm control --reload-rules
