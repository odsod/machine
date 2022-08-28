.PHONY: install
install: \
	~/.local/share/konsole/nord.colorscheme \
	~/.local/share/konsole/odsod.profile

~/.local/share/konsole/nord.colorscheme: nord.colorscheme
	mkdir -p $(dir $@)
	ln -fs $(abspath $<) $@

~/.local/share/konsole/odsod.profile: odsod.profile
	mkdir -p $(dir $@)
	ln -fs $(abspath $<) $@
