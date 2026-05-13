name := machine

# Bootstrap: single entry point for a fresh machine.
# Three phases: pre (human input) → install (unattended) → post (service logins).
.PHONY: bootstrap
bootstrap:
	$(MAKE) bootstrap-pre
	$(MAKE) install
	$(MAKE) bootstrap-post

# Phase 1: requires human interaction (password).
.PHONY: bootstrap-pre
bootstrap-pre: install-sudoers
	@echo "[$(name)] Pre-install complete. Running unattended install next..."

# Phase 3: service logins that require browser/human after software is installed.
.PHONY: bootstrap-post
bootstrap-post:
	@echo "[$(name)] Post-install: authenticate services that need login..."
	@if command -v tailscale >/dev/null && \
		[ "$$(tailscale status --json 2>/dev/null | jq -r '.BackendState // empty')" = "NeedsLogin" ]; then \
		echo "  → Run: sudo tailscale up"; \
	fi
	@if command -v gcloud >/dev/null && \
		! gcloud auth list --filter="status:ACTIVE" --format="value(account)" 2>/dev/null | grep -q .; then \
		echo "  → Run: gcloud auth login"; \
	fi
	@if command -v gh >/dev/null && ! gh auth status >/dev/null 2>&1; then \
		gh auth login -p ssh -w; \
	fi
	@echo "[$(name)] Bootstrap complete."

.PHONY: install
install: \
	~/.profile \
	~/.config/plasma-workspace/env/odsod-machine.sh \
	install-fedora \
	install-agents \
	install-modules


.PHONY: ~/.profile
~/.profile: env.sh
	$(info [$(name)] Symlinking $@...)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.config/plasma-workspace/env/odsod-machine.sh
~/.config/plasma-workspace/env/odsod-machine.sh: env.sh
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: install-fedora
install-fedora:
	$(info [$(name)] Installing Fedora OS layer...)
	@$(MAKE) -C fedora

.PHONY: install-agents
install-agents:
	$(info [$(name)] Installing agents...)
	@$(MAKE) -C jj
	@if ! ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then \
		echo "[$(name)] ERROR: SSH auth to github.com failed. Run: ssh -T git@github.com"; \
		exit 1; \
	fi
	@test -d .agents/.jj || \
		$(HOME)/.local/bin/jj git clone git@github.com:odsod/agents.git .agents
	@$(MAKE) -C .agents

.PHONY: install-modules
install-modules:
	$(info [$(name)] Installing modules...)
	@find . -mindepth 2 -maxdepth 2 -name Makefile \
		-not -path './fedora/*' \
		| while IFS= read -r makefile; do \
			dir=$$(dirname "$$makefile"); \
			$(MAKE) -C "$$dir" || exit $$?; \
		done

.PHONY: install-sudoers
install-sudoers:
	$(info [$(name)] Installing sudoers for odsod...)
	@printf '%s\n' 'odsod ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/odsod >/dev/null
	@sudo chmod 0440 /etc/sudoers.d/odsod
	@sudo visudo -cf /etc/sudoers.d/odsod
