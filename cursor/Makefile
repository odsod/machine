name := cursor
# Discovery: curl -I https://api2.cursor.sh/updates/download/golden/linux-x64-rpm/cursor/latest
# Bump: update version and rpm_url together from `make discover` output.
version := 3.8.24
rpm_url := https://downloads.cursor.com/production/cf80f4b937f3b9c48070d7085129a838ce7876a3/linux/x64/rpm/x86_64/cursor-3.8.24.el8.x86_64.rpm
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)
install_stamp := $(data_dir)/$(version)/cursor-installed.stamp

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
	~/.config/Cursor/User/keybindings.json \
	~/.cursor/cli-config.json \
	~/.cursor/hooks.json \
	~/.cursor/hooks

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

.PHONY: ~/.cursor/cli-config.json
~/.cursor/cli-config.json: cli-config.json
	$(info [$(name)] Merging configuration into $@...)
	@mkdir -p $(dir $@)
	@if [ -f $@ ]; then \
		jq -s '.[0] * .[1]' $@ $< > $@.tmp && mv $@.tmp $@; \
	else \
		cp $< $@; \
	fi

.PHONY: cursor-config-diff
cursor-config-diff:
	@jq -S 'del(.privacyCache, .serverConfigCache, .authInfo, .version, .model, .selectedModel, .modelParameters, .hasChangedDefaultModel, .showSandboxIntro, .runEverythingSettingsPromptStreak)' \
		$(HOME)/.cursor/cli-config.json > /tmp/cursor-live-trackable.json
	@diff -u cli-config.json /tmp/cursor-live-trackable.json || true

.PHONY: ~/.cursor/hooks.json
~/.cursor/hooks.json: hooks.json
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.cursor/hooks
~/.cursor/hooks: hooks
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: install-rpm
install-rpm: $(install_stamp)

$(install_stamp): $(data_dir)/$(version)/cursor.rpm
	$(info [$(name)] Installing RPM...)
	@if [ "$$(rpm -q --qf '%{VERSION}' cursor 2>/dev/null || true)" != "$(version)" ]; then \
		sudo dnf install -y $<; \
	fi
	@touch $@

.PHONY: install-extensions
install-extensions:
	$(info [$(name)] Installing extensions...)
	@for ext in $(extensions); do \
		cursor --install-extension $$ext --force; \
	done

$(data_dir)/$(version)/cursor.rpm:
	$(info [$(name)] Downloading RPM...)
	@mkdir -p $(dir $@)
	@curl -fL $(rpm_url) --create-dirs -Lo $@

.PHONY: discover
discover:
	@location=$$(curl -sI \
		'https://api2.cursor.sh/updates/download/golden/linux-x64-rpm/cursor/latest' \
		| tr -d '\r' | grep -i ^location: | awk '{print $$2}'); \
	version=$$(echo "$$location" | grep -oP 'cursor-\K[0-9]+\.[0-9]+\.[0-9]+' || echo UNKNOWN); \
	printf 'version=%s\nrpm_url=%s\n' "$$version" "$$location"
