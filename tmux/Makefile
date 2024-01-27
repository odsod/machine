name := tmux

.PHONY: install
install: \
	install-packages \
	~/.config/tmux/tmux.conf \
	~/.local/bin/print-tmux-colors

.PHONY: install-packages
install-packages:
	$(info [$(name)] Installing packages...)
	@sudo apt install -y tmux >/dev/null 2>&1

.PHONY: ~/.config/tmux/tmux.conf
~/.config/tmux/tmux.conf: tmux.conf
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.local/bin/print-tmux-colors
~/.local/bin/print-tmux-colors: print-tmux-colors
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@
