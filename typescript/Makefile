name := typescript

# Discovery: https://www.npmjs.com/package/typescript
typescript_version := 6.0.2
# Discovery: https://www.npmjs.com/package/@vtsls/language-server
vtsls_version := 0.3.0

.PHONY: all
all: install

.PHONY: install
install:
	@$(MAKE) -C ../nodejs ~/.local/bin/npm
	@$(MAKE) npm-packages

.PHONY: npm-packages
npm-packages:
	$(info [$(name)] Installing npm packages...)
	@~/.local/bin/npm install -g typescript@$(typescript_version)
	@~/.local/bin/npm install -g @vtsls/language-server@$(vtsls_version)
