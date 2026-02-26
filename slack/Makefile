name := slack
# Discovery (version): https://slack.com/release-notes/linux/rss
# Discovery (rpm): no stable public endpoint for exact RPM build suffix.
# Update `version` and `build` manually, then validate:
# curl -I https://downloads.slack-edge.com/desktop-releases/linux/x64/<version>/slack-<build>.x86_64.rpm
version := 4.47.69
build := 4.47.69-0.1.el8
package_url := https://downloads.slack-edge.com/desktop-releases/linux/x64/$(version)/slack-$(build).x86_64.rpm
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: install-package
install-package: $(data_dir)/$(version)/package.rpm
	$(info [$(name)] Installing package...)
	@if ! rpm -q slack >/dev/null 2>&1; then \
		sudo dnf install -y $<; \
	fi

$(data_dir)/$(version)/package.rpm:
	$(info [$(name)] Downloading package...)
	@curl $(package_url) --create-dirs -Lo $@
	@touch $@
