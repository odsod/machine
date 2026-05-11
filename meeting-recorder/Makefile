name := meeting-recorder

.PHONY: install
install: install-dependencies install-scripts install-service install-shortcut

.PHONY: install-dependencies
install-dependencies:
	$(info [$(name)] Installing dependencies...)
	@sudo dnf install -y -q \
		libnotify \
		pipewire-utils \
		pulseaudio-utils

.PHONY: install-scripts
install-scripts:
	$(info [$(name)] Installing scripts...)
	@mkdir -p $(HOME)/.local/bin
	@install -m 0755 meeting-recorder.py $(HOME)/.local/bin/meeting-recorder
	@install -m 0755 meeting-recorder-toggle $(HOME)/.local/bin/meeting-recorder-toggle

.PHONY: install-service
install-service:
	$(info [$(name)] Installing service...)
	@mkdir -p $(HOME)/.config/systemd/user
	@cp -f meeting-recorder.service $(HOME)/.config/systemd/user/
	@systemctl --user daemon-reload

.PHONY: install-shortcut
install-shortcut:
	$(info [$(name)] Registering KDE global shortcut (Meta+Shift+M)...)
	@if ! kreadconfig6 --file kglobalshortcutsrc --group "meeting-recorder-toggle.desktop" --key "_launch" 2>/dev/null | grep -q "Meta+Shift+M"; then \
		kwriteconfig6 --file kglobalshortcutsrc --group "meeting-recorder-toggle.desktop" --key "_launch" "Meta+Shift+M,none,Toggle Meeting Recorder"; \
		kwriteconfig6 --file kglobalshortcutsrc --group "meeting-recorder-toggle.desktop" --key "_k_friendly_name" "Toggle Meeting Recorder"; \
	fi

.PHONY: uninstall
uninstall:
	$(info [$(name)] Uninstalling...)
	@systemctl --user stop meeting-recorder.service 2>/dev/null || true
	@systemctl --user disable meeting-recorder.service 2>/dev/null || true
	@rm -f $(HOME)/.local/bin/meeting-recorder
	@rm -f $(HOME)/.local/bin/meeting-recorder-toggle
	@rm -f $(HOME)/.config/systemd/user/meeting-recorder.service
	@systemctl --user daemon-reload
