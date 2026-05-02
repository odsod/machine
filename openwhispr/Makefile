name := openwhispr
# Discovery: https://github.com/OpenWhispr/openwhispr/releases/latest
version := 1.6.10
package_url := https://github.com/OpenWhispr/openwhispr/releases/download/v$(version)/OpenWhispr-$(version)-linux-x86_64.rpm
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: install
install: \
	install-dependencies \
	install-package \
	~/.local/bin/openwhispr \
	~/.local/bin/open-whispr

.PHONY: install-dependencies
install-dependencies:
	$(info [$(name)] Installing dependencies...)
	@sudo dnf install -y \
		wl-clipboard \
		xclip \
		xdg-desktop-portal-kde \
		xdotool

.PHONY: install-package
install-package: $(data_dir)/$(version)/package.rpm
	$(info [$(name)] Installing package...)
	@sudo dnf install -y $<

.PHONY: ~/.local/bin/openwhispr ~/.local/bin/open-whispr
~/.local/bin/openwhispr ~/.local/bin/open-whispr: install-package
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT /opt/OpenWhispr/open-whispr $@

$(data_dir)/$(version)/package.rpm:
	$(info [$(name)] Downloading package...)
	@curl -fL $(package_url) --create-dirs -o $@
	@touch $@
