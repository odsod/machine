name := machine

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
	@test -d .agents/.jj || \
		jj git clone git@github.com:odsod/agents.git .agents
	@$(MAKE) -C .agents

.PHONY: install-modules
install-modules:
	$(info [$(name)] Installing modules...)
	@find . -mindepth 2 -maxdepth 2 -name Makefile \
		-not -path './fedora/*' \
		| xargs dirname | xargs -n1 make -C

.PHONY: install-sudoers
install-sudoers:
	$(info [$(name)] Installing sudoers for odsod...)
	@printf '%s\n' 'odsod ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/odsod >/dev/null
	@sudo chmod 0440 /etc/sudoers.d/odsod
	@sudo visudo -cf /etc/sudoers.d/odsod
