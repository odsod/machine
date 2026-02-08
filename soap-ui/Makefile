name := soap-ui
# Discovery: https://www.soapui.org/downloads/soapui/open-source/
version := 5.9.1
archive_url := https://dl.eviware.com/soapuios/$(version)/SoapUI-$(version)-linux-bin.tar.gz
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: ~/.local/bin/$(name)
~/.local/bin/$(name): $(data_dir)/$(version)/SoapUI-$(version)/bin/soapui.sh
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

$(data_dir)/$(version)/SoapUI-$(version)/bin/soapui.sh: $(data_dir)/$(version)/archive.tar.gz
	$(info [$(name)] Extracting $<...)
	@tar -C $(dir $<) -xf $<
	@touch $@
	@chmod +x $@

$(data_dir)/$(version)/archive.tar.gz:
	$(info [$(name)] Downloading $(archive_url)...)
	@curl $(archive_url) --create-dirs -Lo $@
	@touch $@
