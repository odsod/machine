inter_display_version := 3.19
inter_display_archive_url := https://github.com/rsms/inter/releases/download/display-beta-2/Inter-$(inter_display_version)-display-beta-2-7b4e19f9a8.zip

.PHONY: install
install: \
	~/.local/share/fonts/inter-display \
	update-font-cache

.PHONY: ~/.local/share/fonts/inter-display
~/.local/share/fonts/inter-display: .build/$(inter_display_version)/LICENSE.txt
	$(info [inter] symlinking $@)
	@mkdir -p $(dir $@)
	@ln -fsT "$(abspath $(dir $<))/Inter Desktop" $@

.build/$(inter_display_version)/archive.zip:
	$(info [inter] downloading archive)
	@curl $(inter_display_archive_url) --create-dirs -Lo $@

.build/$(inter_display_version)/LICENSE.txt: .build/$(inter_display_version)/archive.zip
	$(info [inter] unzipping $<)
	@unzip $< -d $(dir $@)
	@touch $@

.PHONY: update-font-cache
update-font-cache: ~/.local/share/fonts/inter
	$(info [inter] updating font cache)
	@fc-cache -vf >/dev/null
