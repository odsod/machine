.PHONY: install
install: \
	install-deps \
	install-package

dropbox_version := 2020.03.04

.PHONY: install-deps
install-deps:
	$(info [dropbox] installing dependencies)
	@sudo apt install -y libpango1.0-0 >/dev/null 2>&1

.build/dropbox_$(dropbox_version)_amd64.deb:
	$(info [dropbox] downloading package)
	@mkdir -p $(dir $@)
	@curl -Lo $@ https://www.dropbox.com/download?dl=packages/ubuntu/dropbox_$(dropbox_version)_amd64.deb

.PHONY: install-package
install-package: .build/dropbox_$(dropbox_version)_amd64.deb
	$(info [dropbox] installing package)
	@sudo dpkg -i $< >/dev/null 2>&1
