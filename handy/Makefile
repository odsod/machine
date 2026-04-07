name := handy
# Discovery: https://github.com/cjpais/Handy/releases/latest
version := 0.8.3
release := 1
package_url := https://github.com/cjpais/Handy/releases/download/v$(version)/Handy-$(version)-$(release).x86_64.rpm
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: install
install: \
	install-dependencies \
	install-package \
	~/.local/bin/handy-toggle

.PHONY: install-dependencies
install-dependencies:
	$(info [$(name)] Installing dependencies...)
	@sudo dnf install -y gtk-layer-shell wtype

.PHONY: install-package
install-package: $(data_dir)/$(version)/package.rpm
	$(info [$(name)] Installing package...)
	@sudo dnf install -y $<

.PHONY: ~/.local/bin/handy-toggle
~/.local/bin/handy-toggle: handy-toggle
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

$(data_dir)/$(version)/package.rpm:
	$(info [$(name)] Downloading package...)
	@curl -L $(package_url) --create-dirs -o $@
	@touch $@
