.PHONY: install
install: \
	~/.gitconfig

.PHONY: ~/.gitconfig
~/.gitconfig: gitconfig
	$(info [git] symlinking $@)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@
