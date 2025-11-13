name := cursor
version := 2.0.64
rpm_url := https://downloads.cursor.com/production/25412918da7e74b2686b25d62da1f01cfcd27683/linux/x64/rpm/x86_64/cursor-$(version).el8.x86_64.rpm

.PHONY: all
all: \
	install-rpm \
	~/.config/Cursor/User/settings.json \
	~/.config/Cursor/User/keybindings.json

.PHONY: ~/.config/Cursor/User/settings.json
~/.config/Cursor/User/settings.json: ../vscode/settings.json
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.config/Cursor/User/keybindings.json
~/.config/Cursor/User/keybindings.json: ../vscode/keybindings.json
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: install-rpm
install-rpm: build/$(version)/cursor.rpm
	$(info [$(name)] Installing $@...)
	@sudo dnf install $<

.PHONY: build/$(version)/cursor.rpm
build/$(version)/cursor.rpm:
	$(info [$(name)] Downloading RPM...)
	@mkdir -p build
	@curl -D build/headers.txt $(rpm_url) --create-dirs -Lo $@
	@touch $@
