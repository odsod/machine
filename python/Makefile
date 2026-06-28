name := python

# Discovery: https://pypi.org/project/ruff/
ruff_version := 0.15.20
# Discovery: https://pypi.org/project/ty/
ty_version := 0.0.55

.PHONY: all
all: tools

.PHONY: tools
tools:
	$(info [$(name)] Installing tools...)
	@$(MAKE) -C ../uv install-packages
	@uv tool install ruff@$(ruff_version)
	@uv tool install ty@$(ty_version)

.PHONY: discover
discover:
	@printf 'ruff_version=%s\n' "$$(curl -s https://pypi.org/pypi/ruff/json \
		| jq -r '.info.version // "UNKNOWN"')"
	@printf 'ty_version=%s\n' "$$(curl -s https://pypi.org/pypi/ty/json \
		| jq -r '.info.version // "UNKNOWN"')"
