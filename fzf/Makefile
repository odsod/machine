name := fzf

.PHONY: install
install: install-packages

.PHONY: install-packages
install-packages:
	$(info [$(name)] Installing fzf and companions (fd, bat, ripgrep)...)
	@sudo dnf install -y fzf fd-find bat ripgrep
