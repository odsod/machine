name := nodejs

node_version := 24.13.1
pnpm_version := 10.29.3

pnpm_url := https://github.com/pnpm/pnpm/releases/download/v$(pnpm_version)/pnpm-linux-x64
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: install
install: \
	install-packages \
	~/.local/bin/node \
	~/.local/bin/npm \
	~/.local/bin/npx \
	~/.local/bin/pnpm \
	~/.npmrc

.PHONY: install-packages
install-packages:
	$(info [$(name)] Installing packages...)
	@sudo dnf install -y \
		nodejs24 \
		nodejs24-npm
	@sudo sed -i '/^python=/d' /etc/npmrc || true

.PHONY: ~/.local/bin/node
~/.local/bin/node:
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT /usr/bin/node-24 $@

.PHONY: ~/.local/bin/npm
~/.local/bin/npm:
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT /usr/bin/npm-24 $@

.PHONY: ~/.local/bin/npx
~/.local/bin/npx:
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT /usr/bin/npx-24 $@

.PHONY: ~/.local/bin/pnpm
~/.local/bin/pnpm: $(data_dir)/pnpm/$(pnpm_version)/pnpm
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

$(data_dir)/pnpm/$(pnpm_version)/pnpm:
	$(info [$(name)] Downloading pnpm $(pnpm_version)...)
	@mkdir -p $(dir $@)
	@curl -L $(pnpm_url) -o $@
	@chmod +x $@

.PHONY: ~/.npmrc
~/.npmrc: npmrc
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@
