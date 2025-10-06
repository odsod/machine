name := cursor
version := 1.7
rpm_url := https://api2.cursor.sh/updates/download/golden/linux-x64-rpm/cursor/$(version)

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
