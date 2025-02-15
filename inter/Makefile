name := inter
version := 4.1
archive_url := https://github.com/rsms/inter/releases/download/v$(version)/Inter-$(version).zip

.PHONY: ~/.local/share/fonts/inter.ttc
~/.local/share/fonts/inter.ttc: build/$(version)/Inter.ttc
	$(info [$(name)] Installing...)
	@mkdir -p ~/.local/share/fonts
	@ln -fs $(abspath $<) $@
	@fc-cache -vf >/dev/null

build/$(version)/Inter.ttc: build/$(version)/archive.zip
	$(info [$(name)] Unzipping $<...)
	@unzip $< -d $(dir $@)
	@touch $@

build/$(version)/archive.zip:
	$(info [$(name)] Downloading $(archive_url)...)
	@curl $(archive_url) --create-dirs -Lo $@
	@touch $@
