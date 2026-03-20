name := python

# Discovery: https://pypi.org/project/ruff/
ruff_version := 0.15.7
# Discovery: https://pypi.org/project/ty/
ty_version := 0.0.24

.PHONY: all
all: tools

.PHONY: tools
tools:
	$(info [$(name)] Installing tools...)
	@uv tool install ruff@$(ruff_version)
	@uv tool install ty@$(ty_version)
