.PHONY: install
install: \
	install-packages \
	~/.bashrc \
	~/.inputrc \
	~/.local/bin/print-bash-colors \
	~/.config/bash/prompt.bash

.PHONY: install-packages
install-packages:
	$(info [bash] installing packages)
	@sudo apt install -y direnv >/dev/null 2>&1

.PHONY: ~/.bashrc
~/.bashrc: bashrc
	$(info [bash] symlinking $@)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.inputrc
~/.inputrc: inputrc
	$(info [bash] symlinking $@)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.local/bin/print-bash-colors
~/.local/bin/print-bash-colors: print-bash-colors
	$(info [bash] symlinking $@)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.config/bash/prompt.bash
~/.config/bash/prompt.bash: prompt.bash
	$(info [bash] symlinking $@)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@
