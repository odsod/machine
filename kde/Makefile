.PHONY: install
install: \
	~/.config/plasma-workspace/env/ssh-agent-startup.sh \
	~/.config/plasma-workspace/shutdown/ssh-agent-shutdown.sh

~/.config/plasma-workspace/env/ssh-agent-startup.sh: ssh-agent-startup.sh
	mkdir -p $(dir $@)
	ln -fs $(abspath $<) $@

~/.config/plasma-workspace/shutdown/ssh-agent-shutdown.sh: ssh-agent-shutdown.sh
	mkdir -p $(dir $@)
	ln -fs $(abspath $<) $@
