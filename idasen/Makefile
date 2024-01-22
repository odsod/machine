name := idasen
version := 0.11.1
venv_dir := build/$(version)/venv
venv_pip := build/$(version)/venv/bin/pip
cmd := build/$(version)/venv/bin/$(name)
cmd_symlink := ~/.local/bin/$(name)
config := idasen.yaml
config_symlink := ~/.config/idasen/$(config)

.PHONY: all
all: $(config_symlink) $(cmd_symlink)

.PHONY: $(config_symlink)
$(config_symlink): $(config)
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: $(cmd_symlink)
$(cmd_symlink): $(cmd)
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

$(cmd): $(venv_pip)
	$(info [$(name)] Installing Python package...)
	@$(venv_pip) install $(name)
	@touch $@

$(venv_pip):
	$(info [$(name)] Initializing virtualenv...)
	@python3 -m venv $(venv_dir)
