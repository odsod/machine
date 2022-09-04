.PHONY: install
install: \
	~/.config/plasma-workspace/env/ssh-agent-startup.sh \
	~/.config/plasma-workspace/shutdown/ssh-agent-shutdown.sh

.PHONY: ~/.config/plasma-workspace/env/ssh-agent-startup.sh
~/.config/plasma-workspace/env/ssh-agent-startup.sh: ssh-agent-startup.sh
	$(info [kde] symlinking $@)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.config/plasma-workspace/shutdown/ssh-agent-shutdown.sh
~/.config/plasma-workspace/shutdown/ssh-agent-shutdown.sh: ssh-agent-shutdown.sh
	$(info [kde] symlinking $@)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@
