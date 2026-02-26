name := cursor
include ../vscode/extensions.mk
# Discovery: curl -I https://api2.cursor.sh/updates/download/golden/linux-x64-rpm/cursor/latest
version := 2.5.25
rpm_url := https://downloads.cursor.com/production/7150844152b426ed50d2b68dd6b33b5c5beb73ca/linux/x64/rpm/x86_64/cursor-$(version).el8.x86_64.rpm
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: all
all: \
	install-rpm \
	install-extensions \
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
	@if ! rpm -q cursor >/dev/null 2>&1; then \
		sudo dnf install -y $<; \
	fi

.PHONY: install-extensions
install-extensions:
	$(info [$(name)] Installing extensions...)
	@for ext in $(EDITOR_EXTENSIONS); do \
		cursor --install-extension $$ext --force; \
	done

$(data_dir)/$(version)/cursor.rpm:
	$(info [$(name)] Downloading RPM...)
	@mkdir -p $(dir $@)
	@curl -D $(data_dir)/$(version)/headers.txt $(rpm_url) --create-dirs -Lo $@
	@touch $@
