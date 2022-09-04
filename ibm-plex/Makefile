ibm_plex_version := 6.1.0
ibm_plex_archive_url := https://github.com/IBM/plex/releases/download/v$(ibm_plex_version)/OpenType.zip

.PHONY: install
install: ~/.local/share/fonts/ibm-plex
	fc-cache -vf

.PHONY: ~/.local/share/fonts/ibm-plex
~/.local/share/fonts/ibm-plex: .build/$(ibm_plex_version)/OpenType
	mkdir -p ~/.local/share/fonts
	ln -fsT $(abspath $<) $@

.build/$(ibm_plex_version)/OpenType.zip:
	curl $(ibm_plex_archive_url) --create-dirs -Lo $@

.build/$(ibm_plex_version)/OpenType: .build/$(ibm_plex_version)/OpenType.zip
	unzip $< -d $(dir $@)
	touch $@
