.PHONY: install
install: \
	~/.config/plasma-workspace/env/path.sh

.PHONY: install-deps
install-deps:
	sudo add-apt-repository ppa:kubuntu-ppa/backports
	sudo apt upgrade

~/.config/plasma-workspace/env/path.sh: path.sh
	mkdir -p $(dir $@)
	ln -fs $(abspath $<) $@
