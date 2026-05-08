name := slack
# Reference: no stable public endpoint for exact RPM build suffix.
# Update `version` and `build` manually, then validate:
# curl -I https://downloads.slack-edge.com/desktop-releases/linux/x64/<version>/slack-<build>.x86_64.rpm
# Discovery: https://slack.com/release-notes/linux/rss
version := 4.49.89
# Discovery: curl -I https://downloads.slack-edge.com/desktop-releases/linux/x64/<version>/slack-<build>.x86_64.rpm
build := 4.49.89-0.1.el8
package_url := https://downloads.slack-edge.com/desktop-releases/linux/x64/$(version)/slack-$(build).x86_64.rpm
signing_key_url := https://slack.com/gpg/slack_pubkey_20251016.gpg
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: install-package
install-package: $(data_dir)/$(version)/package.rpm $(data_dir)/$(version)/signing-key.gpg
	$(info [$(name)] Installing package...)
	@sudo rpm --import $(data_dir)/$(version)/signing-key.gpg
	@rpm -Kv $(data_dir)/$(version)/package.rpm
	@if ! rpm -q slack-$(build).x86_64 >/dev/null 2>&1; then \
		sudo dnf install -y $<; \
	fi

$(data_dir)/$(version)/package.rpm:
	$(info [$(name)] Downloading package...)
	@curl $(package_url) --create-dirs -Lo $@
	@touch $@

$(data_dir)/$(version)/signing-key.gpg:
	$(info [$(name)] Downloading signing key...)
	@curl $(signing_key_url) --create-dirs -Lo $@
	@touch $@
