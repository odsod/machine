name := fish

.PHONY: install
install: \
	install-packages \
	~/.config/fish/config.fish \
	~/.config/fish/conf.d/fzf.fish \
	change-shell

.PHONY: change-shell
change-shell: install-packages
	$(info [$(name)] Changing login shell...)
	@if [ "$$SHELL" != "$$(which fish)" ]; then \
		chsh -s $$(which fish); \
	fi

.PHONY: install-packages
install-packages:
	$(info [$(name)] Installing package...)
	@sudo dnf install -y fish

.PHONY: ~/.config/fish/config.fish
~/.config/fish/config.fish: config.fish
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.config/fish/conf.d/fzf.fish
~/.config/fish/conf.d/fzf.fish: install-packages
	$(info [$(name)] Generating fzf init...)
	@mkdir -p $(dir $@)
	@fzf --fish > $@
