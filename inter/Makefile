inter_version := 3.19
inter_archive_url := https://github.com/rsms/inter/releases/download/v$(inter_version)/Inter-$(inter_version).zip

.PHONY: install
install: \
	~/.local/share/fonts/inter \
	update-font-cache

.PHONY: ~/.local/share/fonts/inter
~/.local/share/fonts/inter: .build/$(inter_version)/LICENSE.txt
	$(info [inter] symlinking $@)
	@mkdir -p $(dir $@)
	@ln -fsT "$(abspath $(dir $<))/Inter Desktop" $@

.build/$(inter_version)/archive.zip:
	$(info [inter] downloading archive)
	@curl $(inter_archive_url) --create-dirs -Lo $@

.build/$(inter_version)/LICENSE.txt: .build/$(inter_version)/archive.zip
	$(info [inter] unzipping $<)
	@unzip $< -d $(dir $@)
	@touch $@

.PHONY: update-font-cache
update-font-cache: ~/.local/share/fonts/inter
	$(info [inter] updating font cache)
	@fc-cache -vf >/dev/null
