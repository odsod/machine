.PHONY: install
install: \
	install-deps \
	install-deb

dropbox_version := 2020.03.04

.PHONY: install-deps
install-deps:
	sudo apt install libpango1.0-0

.build/dropbox_$(dropbox_version)_amd64.deb:
	mkdir -p $(dir $@)
	curl -Lo $@ https://www.dropbox.com/download?dl=packages/ubuntu/dropbox_$(dropbox_version)_amd64.deb

.PHONY: install-deb
install-deb: .build/dropbox_$(dropbox_version)_amd64.deb
	sudo dpkg -i $<
