name := fx
version := 39.1.0
bin_url := https://github.com/antonmedv/fx/releases/download/$(version)/fx_linux_amd64

.PHONY: ~/.local/bin/fx
~/.local/bin/fx: build/$(version)/fx
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

build/$(version)/fx:
	$(info [$(name)] Downloading binary...)
	@curl $(bin_url) --create-dirs -Lo $@
	@touch $@
	@chmod +x $@
