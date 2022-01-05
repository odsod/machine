.PHONY: install
install: \
	~/.config/tmux/tmux.conf

~/.config/tmux/tmux.conf: tmux.conf
	mkdir -p $(dir $@)
	ln -fs $(abspath $<) $@
