ibm_plex_version := 6.1.0
ibm_plex_archive_url := https://github.com/IBM/plex/releases/download/v$(ibm_plex_version)/OpenType.zip

.PHONY: install
install: \
	~/.local/share/fonts/ibm-plex \
	update-font-cache

.PHONY: ~/.local/share/fonts/ibm-plex
~/.local/share/fonts/ibm-plex: .build/$(ibm_plex_version)/OpenType
	$(info [ibm-plex] symlinking $@)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.build/$(ibm_plex_version)/OpenType.zip:
	$(info [ibm-plex] downloading archive)
	@curl $(ibm_plex_archive_url) --create-dirs -Lo $@

.build/$(ibm_plex_version)/OpenType: .build/$(ibm_plex_version)/OpenType.zip
	$(info [ibm-plex] unzipping $<)
	@unzip $< -d $(dir $@)
	@touch $@

.PHONY: update-font-cache
update-font-cache: ~/.local/share/fonts/ibm-plex
	$(info [ibm-plex] updating font cache)
	@fc-cache -vf >/dev/null
