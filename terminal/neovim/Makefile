.PHONY: install
install: \
	add-ppa \
	install-package \
	~/.local/share/nvim/site/autoload/plug.vim \
	~/.config/environment.d/10-odsod-desktop-neovim.conf

.PHONY: add-ppa
add-ppa:
	@dpkg-query -W neovim >/dev/null || sudo add-apt-repository ppa:neovim-ppa/unstable

.PHONY: install-package
install-package:
	@dpkg-query -W neovim >/dev/null || sudo apt install neovim

~/.local/share/nvim/site/autoload/plug.vim:
	mkdir -p $(dir $@)
	curl -o $@ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

~/.config/environment.d/10-odsod-desktop-neovim.conf:
	mkdir -p $(dir $@)
	echo EDITOR=vim > $@
