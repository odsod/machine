name := idasen
# Discovery: https://pypi.org/pypi/idasen/json
version := 0.12.0
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)
venv_dir := $(data_dir)/$(version)/venv
venv_pip := $(venv_dir)/bin/pip
cmd := $(venv_dir)/bin/$(name)
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
	@mkdir -p $(dir $@)
	@python3 -m venv $(venv_dir)
