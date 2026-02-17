name := yaak
# Discovery: https://github.com/mountain-loop/yaak/releases/latest
version := 2026.2.1
package_url := https://github.com/mountain-loop/yaak/releases/download/v$(version)/yaak-$(version)-1.x86_64.rpm
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: install-package
install-package: $(data_dir)/$(version)/package.rpm
	$(info [$(name)] Installing package...)
	@sudo dnf install -y $<

$(data_dir)/$(version)/package.rpm:
	$(info [$(name)] Downloading package...)
	@curl $(package_url) --create-dirs -Lo $@
	@touch $@
