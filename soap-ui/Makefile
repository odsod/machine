name := soap-ui
version := 5.9.0
archive_url := https://dl.eviware.com/soapuios/$(version)/SoapUI-$(version)-linux-bin.tar.gz

.PHONY: ~/.local/bin/soap-ui
~/.local/bin/soap-ui: build/$(version)/SoapUI-$(version)/bin/soapui.sh
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

build/$(version)/SoapUI-$(version)/bin/soapui.sh: build/$(version)/archive.tar.gz
	$(info [$(name)] Extracting archive...)
	@tar -C $(dir $<) -xf $<
	@touch $@
	@chmod +x $@

build/$(version)/archive.tar.gz:
	$(info [$(name)] Downloading archive...)
	@curl $(archive_url) --create-dirs -Lo $@
	@touch $@
