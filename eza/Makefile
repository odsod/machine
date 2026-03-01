name := eza
version := 0.23.4
# Discovery: https://github.com/eza-community/eza/releases/latest
url := https://github.com/eza-community/eza/releases/download/v$(version)/eza_x86_64-unknown-linux-gnu.tar.gz

bin_dir := $(HOME)/.local/bin
install_dir := $(HOME)/.local/share/odsod/machine/data/$(name)/$(version)

.PHONY: install
install:
	$(info [$(name)] Installing...)
	@mkdir -p "$(install_dir)"
	@curl -sL "$(url)" | tar -xz -C "$(install_dir)"
	@mkdir -p "$(bin_dir)"
	@ln -fsT "$(install_dir)/eza" "$(bin_dir)/eza"
