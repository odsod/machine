name := agents

.PHONY: all
all: \
	~/.gemini/GEMINI.md \
	~/.claude/CLAUDE.md

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
