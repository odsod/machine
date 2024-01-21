name := shfmt
version := 3.7.0
cmd_url := https://github.com/mvdan/sh/releases/download/v3.7.0/shfmt_v3.7.0_linux_amd64
cmd := build/$(version)/$(name)
symlink := ~/.local/bin/$(name)

.PHONY: $(symlink)
$(symlink): $(cmd)
	$(info [$(name)] symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

$(cmd):
	$(info [$(name)] downloading $(cmd_url)...)
	@curl $(cmd_url) --create-dirs -Lo $@
	@touch $@
	@chmod +x $@
