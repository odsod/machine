.PHONY: install
install: \
	~/.config/alacritty/alacritty.yml \
	~/.local/bin/alacrittymux

~/.config/alacritty/alacritty.yml: alacritty.yml
	mkdir -p $(dir $@)
	ln -fs $(abspath $<) $@

~/.local/bin/alacrittymux: alacrittymux
	mkdir -p $(dir $@)
	ln -fs $(abspath $<) $@
