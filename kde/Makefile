.PHONY: ~/.config/mimeapps.list
~/.config/mimeapps.list: mimeapps.list
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@
