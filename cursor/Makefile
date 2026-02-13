name := cursor
# Discovery: curl -I https://api2.cursor.sh/updates/download/golden/linux-x64-rpm/cursor/latest
version := 2.4.36
rpm_url := https://downloads.cursor.com/production/f9919bf991f247689f9ead605b5c5a3239a2a794/linux/x64/rpm/x86_64/cursor-$(version).el8.x86_64.rpm
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

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
install-rpm: $(data_dir)/$(version)/cursor.rpm
	$(info [$(name)] Installing $@...)
	@sudo dnf install -y $<

$(data_dir)/$(version)/cursor.rpm:
	$(info [$(name)] Downloading RPM...)
	@mkdir -p $(dir $@)
	@curl -D $(data_dir)/$(version)/headers.txt $(rpm_url) --create-dirs -Lo $@
	@touch $@
