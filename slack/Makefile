name := slack
# Discovery: https://slack.com/release-notes/linux
version := 4.47.69
build := 4.47.69-0.1.el8
package_url := https://downloads.slack-edge.com/desktop-releases/linux/x64/$(version)/slack-$(build).x86_64.rpm
data_dir := $(HOME)/.local/share/odsod/machine/$(name)

.PHONY: install-package
install-package: $(data_dir)/$(version)/package.rpm
	$(info [$(name)] Installing package...)
	@sudo dnf install -y $<

$(data_dir)/$(version)/package.rpm:
	$(info [$(name)] Downloading package...)
	@curl $(package_url) --create-dirs -Lo $@
	@touch $@
