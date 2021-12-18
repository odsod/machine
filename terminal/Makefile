.PHONY: install
install: \
	install-deps \
	~/.config/alacritty/alacritty.yml \
	~/.local/bin/alacrittymux \
	~/.config/tmux/tmux.conf

.PHONY: install-deps
install-deps:
	sudo add-apt-repository ppa:mmstick76/alacritty
	sudo apt install -y tmux alacritty

~/.config/alacritty/alacritty.yml: alacritty.yml
	mkdir -p $(dir $@)
	ln -fs $(abspath $<) $@

~/.local/bin/alacrittymux: alacrittymux
	mkdir -p $(dir $@)
	ln -fs $(abspath $<) $@

~/.config/tmux/tmux.conf: tmux.conf
	mkdir -p $(dir $@)
	ln -fs $(abspath $<) $@
