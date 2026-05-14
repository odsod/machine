name := mise
# Discovery: https://github.com/jdx/mise/releases/latest
version := 2026.5.7
url := https://github.com/jdx/mise/releases/download/v$(version)/mise-v$(version)-linux-x64.tar.gz

bin_dir := $(HOME)/.local/bin
install_dir := $(HOME)/.local/share/odsod/machine/data/$(name)/$(version)

.PHONY: install
install:
	$(info [$(name)] Installing...)
	@mkdir -p "$(install_dir)"
	@curl -sL "$(url)" | tar -xz -C "$(install_dir)" --strip-components=1
	@mkdir -p "$(bin_dir)"
	@ln -fsT "$(install_dir)/bin/mise" "$(bin_dir)/mise"
