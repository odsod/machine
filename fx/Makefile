name := fx
# Discovery: https://github.com/antonmedv/fx/releases/latest
version := 39.2.0
bin_url := https://github.com/antonmedv/fx/releases/download/$(version)/fx_linux_amd64
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: ~/.local/bin/fx
~/.local/bin/fx: $(data_dir)/$(version)/fx
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

$(data_dir)/$(version)/fx:
	$(info [$(name)] Downloading binary...)
	@curl $(bin_url) --create-dirs -Lo $@
	@touch $@
	@chmod +x $@
