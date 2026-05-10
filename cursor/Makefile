name := cursor
# Discovery: curl -I https://api2.cursor.sh/updates/download/golden/linux-x64-rpm/cursor/latest
version := 3.3.30
rpm_url := https://downloads.cursor.com/production/3dc559280adc5f931ade8e25c7b85393842acf34/linux/x64/rpm/x86_64/cursor-$(version).el8.x86_64.rpm
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

extensions := \
	arcticicestudio.nord-visual-studio-code \
	golang.go \
	ms-python.python \
	vscodevim.vim \
	bufbuild.vscode-buf \
	bierner.markdown-mermaid \
	redhat.vscode-yaml \
	charliermarsh.ruff \
	oxc.oxc-vscode

.PHONY: all
all: \
	install-rpm \
	install-extensions \
	~/.config/Cursor/User/settings.json \
	~/.config/Cursor/User/keybindings.json

.PHONY: ~/.config/Cursor/User/settings.json
~/.config/Cursor/User/settings.json: settings.json
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.config/Cursor/User/keybindings.json
~/.config/Cursor/User/keybindings.json: keybindings.json
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
	@for ext in $(extensions); do \
		cursor --install-extension $$ext --force; \
	done

$(data_dir)/$(version)/cursor.rpm:
	$(info [$(name)] Downloading RPM...)
	@mkdir -p $(dir $@)
	@curl -D $(data_dir)/$(version)/headers.txt $(rpm_url) --create-dirs -Lo $@
	@touch $@
