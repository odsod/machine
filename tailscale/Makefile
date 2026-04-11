name := tailscale

.PHONY: install
install: install-package enable-service ~/.local/bin/remote-tmux

.PHONY: install-package
install-package:
	$(info [$(name)] Installing package...)
	@sudo dnf config-manager addrepo --overwrite --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo
	@sudo dnf install -y tailscale

.PHONY: enable-service
enable-service: install-package
	$(info [$(name)] Enabling service...)
	@sudo systemctl enable --now tailscaled

.PHONY: ~/.local/bin/remote-tmux
~/.local/bin/remote-tmux: remote-tmux.fish
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@
