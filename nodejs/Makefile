name := nodejs

# Track the RPM-provided Node.js LTS stream on this machine.
# Skip this module during routine version bumps.
# Only bump `node_major` when Fedora moves to a new Node.js LTS stream.
# DNF keeps the exact Node.js and npm versions current within that stream.
# Discovery: https://nodejs.org/en/about/previous-releases
node_major := 24
# Discovery: https://github.com/pnpm/pnpm/releases/latest
pnpm_version := 11.0.8

pnpm_url := https://github.com/pnpm/pnpm/releases/download/v$(pnpm_version)/pnpm-linux-x64.tar.gz
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
		nodejs$(node_major) \
		nodejs$(node_major)-npm

.PHONY: ~/.local/bin/node
~/.local/bin/node: install-packages
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT /usr/bin/node-$(node_major) $@

.PHONY: ~/.local/bin/npm
~/.local/bin/npm: install-packages
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT /usr/bin/npm-$(node_major) $@

.PHONY: ~/.local/bin/npx
~/.local/bin/npx: install-packages
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT /usr/bin/npx-$(node_major) $@

.PHONY: ~/.local/bin/pnpm
~/.local/bin/pnpm: $(data_dir)/pnpm/$(pnpm_version)/pnpm
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

$(data_dir)/pnpm/$(pnpm_version)/pnpm: $(data_dir)/pnpm/$(pnpm_version)/archive.tar.gz
	$(info [$(name)] Extracting pnpm $(pnpm_version)...)
	@tar -C $(dir $@) -xzf $<
	@chmod +x $@

$(data_dir)/pnpm/$(pnpm_version)/archive.tar.gz:
	$(info [$(name)] Downloading pnpm $(pnpm_version)...)
	@mkdir -p $(dir $@)
	@curl -L $(pnpm_url) -o $@

.PHONY: ~/.npmrc
~/.npmrc: npmrc
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@
