name := python

# Discovery: https://pypi.org/project/ruff/
ruff_version := 0.15.14
# Discovery: https://pypi.org/project/ty/
ty_version := 0.0.39

.PHONY: all
all: tools

.PHONY: tools
tools:
	$(info [$(name)] Installing tools...)
	@$(MAKE) -C ../uv install-packages
	@uv tool install ruff@$(ruff_version)
	@uv tool install ty@$(ty_version)
