name := konsole

.PHONY: install
install: \
	~/.local/share/konsole/nord.colorscheme \
	~/.local/share/konsole/odsod.profile

.PHONY: ~/.local/share/konsole/nord.colorscheme
~/.local/share/konsole/nord.colorscheme: nord.colorscheme
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.local/share/konsole/odsod.profile
~/.local/share/konsole/odsod.profile: odsod.profile
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@
