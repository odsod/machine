name := bash

.PHONY: install
install: \
	install-packages \
	~/.bashrc \
	~/.inputrc \
	~/.local/bin/print-bash-colors \
	~/.config/bash/prompt.bash

.PHONY: install-packages
install-packages:
	$(info [$(name)] Installing packages...)
	@sudo apt-get install -y \
		direnv \
		| sed -e "s/^/[$(name):$@] /"

.PHONY: ~/.bashrc
~/.bashrc: bashrc
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.inputrc
~/.inputrc: inputrc
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.local/bin/print-bash-colors
~/.local/bin/print-bash-colors: print-bash-colors
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.config/bash/prompt.bash
~/.config/bash/prompt.bash: prompt.bash
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@
