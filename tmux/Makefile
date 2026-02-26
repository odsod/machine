name := tmux
# Discovery: https://api.github.com/repos/tmux/tmux/releases/latest
version := 3.6a

data_dir := $(HOME)/.local/share/odsod/machine/data/tmux/$(version)
src_dir := $(data_dir)/src
tarball := $(data_dir)/tmux-$(version).tar.gz
tmux_bin := $(data_dir)/bin/tmux

.PHONY: install reload
install: \
        install-packages \
        $(tmux_bin) \
        ~/.local/bin/tmux \
        ~/.local/share/man/man1/tmux.1 \
        ~/.config/tmux/tmux.conf \
        ~/.local/bin/print-tmux-colors \
        ~/.local/bin/start-worktree-session \
        ~/.config/smug/worktree.yml

.PHONY: reload
reload:
	$(info [$(name)] Reloading config...)
	@tmux source-file ~/.config/tmux/tmux.conf
.PHONY: install-packages
install-packages:
	$(info [$(name)] Installing packages...)
	@sudo dnf install -y gcc make libevent-devel ncurses-devel bison >/dev/null 2>&1
	@sudo dnf remove -y tmux >/dev/null 2>&1

$(tarball):
	$(info [$(name)] Downloading $(version)...)
	@mkdir -p $(dir $@)
	@curl -sL https://github.com/tmux/tmux/releases/download/$(version)/tmux-$(version).tar.gz -o $@

$(src_dir)/configure: $(tarball)
	$(info [$(name)] Extracting $(version)...)
	@mkdir -p $(src_dir)
	@tar -xzf $< -C $(src_dir) --strip-components=1
	@touch $@

$(tmux_bin): $(src_dir)/configure
	$(info [$(name)] Compiling $(version) from source...)
	@cd $(src_dir) && ./configure --prefix=$(data_dir) >/dev/null 2>&1 && make -j$(nproc) >/dev/null 2>&1 && make install >/dev/null 2>&1

.PHONY: ~/.local/bin/tmux
~/.local/bin/tmux: $(tmux_bin)
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.local/share/man/man1/tmux.1
~/.local/share/man/man1/tmux.1: $(tmux_bin)
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(data_dir)/share/man/man1/tmux.1 $@

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

.PHONY: ~/.local/bin/start-worktree-session
~/.local/bin/start-worktree-session: start-worktree-session.fish
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.config/smug/worktree.yml
~/.config/smug/worktree.yml: worktree.yml
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@
