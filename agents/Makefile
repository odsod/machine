name := agents

.PHONY: all
all: \
	~/.gemini/GEMINI.md \
	~/.claude/CLAUDE.md \
	~/.codex/AGENTS.md

.PHONY: ~/.gemini/GEMINI.md
~/.gemini/GEMINI.md: AGENTS.md
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.claude/CLAUDE.md
~/.claude/CLAUDE.md: AGENTS.md
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.codex/AGENTS.md
~/.codex/AGENTS.md: AGENTS.md
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@
