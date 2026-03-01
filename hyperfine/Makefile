name := hyperfine
version := 1.20.0
# Discovery: https://github.com/sharkdp/hyperfine/releases/latest
url := https://github.com/sharkdp/hyperfine/releases/download/v$(version)/hyperfine-v$(version)-x86_64-unknown-linux-gnu.tar.gz

bin_dir := $(HOME)/.local/bin
install_dir := $(HOME)/.local/share/odsod/machine/data/$(name)/$(version)

.PHONY: install
install:
	$(info [$(name)] Installing...)
	@mkdir -p "$(install_dir)"
	@curl -sL "$(url)" | tar -xz -C "$(install_dir)" --strip-components=1
	@mkdir -p "$(bin_dir)"
	@ln -fsT "$(install_dir)/hyperfine" "$(bin_dir)/hyperfine"
