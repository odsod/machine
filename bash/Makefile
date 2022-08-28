.PHONY: install
install: \
	~/.bashrc \
	~/.inputrc \
	~/.local/bin/print-bash-colors \
	~/.config/bash/prompt.bash \
	install-packages

.PHONY: install-packages
install-packages:
	sudo apt install direnv

~/.bashrc: bashrc
	mkdir -p $(dir $@)
	ln -fs $(abspath $<) $@

~/.inputrc: inputrc
	mkdir -p $(dir $@)
	ln -fs $(abspath $<) $@

~/.local/bin/print-bash-colors: print-bash-colors
	mkdir -p $(dir $@)
	ln -fs $(abspath $<) $@

~/.config/bash/prompt.bash: prompt.bash
	mkdir -p $(dir $@)
	ln -fs $(abspath $<) $@
