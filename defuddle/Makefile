name := defuddle
# Discovery: https://registry.npmjs.org/defuddle/latest
version := 0.17.0
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)
npm_bin := $(HOME)/.local/share/npm/bin/$(name)

.PHONY: install
install: ~/.local/bin/$(name)

.PHONY: ~/.local/bin/$(name)
~/.local/bin/$(name): $(data_dir)/$(version)/installed
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(npm_bin) $@

$(data_dir)/$(version)/installed:
	$(info [$(name)] Installing $(name)@$(version) with npm...)
	@$(MAKE) -C ../nodejs ~/.local/bin/npm
	@~/.local/bin/npm install -g $(name)@$(version)
	@mkdir -p $(dir $@)
	@touch $@
