name := typescript

# Discovery: https://www.npmjs.com/package/typescript
typescript_version := 5.9.3
# Discovery: https://www.npmjs.com/package/@vtsls/language-server
vtsls_version := 0.3.0

.PHONY: all
all: tools

.PHONY: tools
tools:
	$(info [$(name)] Installing tools...)
	@npm install -g typescript@$(typescript_version)
	@npm install -g @vtsls/language-server@$(vtsls_version)
