inter_version := 4.0-beta9h
inter_archive_url := https://github.com/rsms/inter/releases/download/v$(inter_version)/Inter-$(inter_version).zip

.PHONY: install
install: ~/.local/share/fonts/inter.ttc

.PHONY: ~/.local/share/fonts/inter.ttc
~/.local/share/fonts/inter.ttc: build/$(inter_version)/Inter.ttc
	$(info [inter] installing...)
	@mkdir -p ~/.local/share/fonts
	@ln -fs $(abspath $<) $@
	@fc-cache -vf >/dev/null

build/$(inter_version)/Inter.ttc: build/$(inter_version)/Inter.zip
	$(info [inter] unzipping $<...)
	@unzip $< -d $(dir $@)
	@touch $@

build/$(inter_version)/Inter.zip:
	$(info [inter] downloading...)
	@curl $(inter_archive_url) --create-dirs -Lo $@
	@touch $@
