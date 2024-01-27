name := git

.PHONY: install
install: \
	~/.gitconfig

.PHONY: ~/.gitconfig
~/.gitconfig: gitconfig
	$(info [$(name)] Symlinking... $@)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@
