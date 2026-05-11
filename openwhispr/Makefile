name := openwhispr
# Discovery: https://github.com/OpenWhispr/openwhispr/releases/latest
version := 1.7.0
package_url := https://github.com/OpenWhispr/openwhispr/releases/download/v$(version)/OpenWhispr-$(version)-linux-x86_64.rpm
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: install
install: \
	install-dependencies \
	install-package \
	~/.local/bin/openwhispr \
	~/.local/bin/open-whispr \
	install-paste-wrapper \
	input-group

.PHONY: install-dependencies
install-dependencies:
	$(info [$(name)] Installing dependencies...)
	@sudo dnf install -y \
		kdotool \
		wl-clipboard \
		xclip \
		xdg-desktop-portal-kde \
		ydotool

.PHONY: install-package
install-package: $(data_dir)/$(version)/package.rpm
	$(info [$(name)] Installing package...)
	@sudo dnf install -y $<

.PHONY: ~/.local/bin/openwhispr ~/.local/bin/open-whispr
~/.local/bin/openwhispr ~/.local/bin/open-whispr: install-package
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT /opt/OpenWhispr/open-whispr $@

paste_wrapper_src := linux-fast-paste.sh
paste_wrapper_dst := /opt/OpenWhispr/resources/bin/linux-fast-paste

.PHONY: install-paste-wrapper
install-paste-wrapper: install-package
	$(info [$(name)] Installing paste wrapper...)
	@if [ -f $(paste_wrapper_dst) ] && ! [ -f $(paste_wrapper_dst).real ]; then \
		sudo mv $(paste_wrapper_dst) $(paste_wrapper_dst).real; \
	fi
	@sudo install -m 0755 $(paste_wrapper_src) $(paste_wrapper_dst)

.PHONY: input-group
input-group:
	@if ! id -nG | grep -qw input; then \
		sudo usermod -aG input $(USER); \
		$(info [$(name)] Added $(USER) to input group (re-login required for push-to-talk)); \
	fi

$(data_dir)/$(version)/package.rpm:
	$(info [$(name)] Downloading package...)
	@curl -fL $(package_url) --create-dirs -o $@
	@touch $@
