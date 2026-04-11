name := typescript

# Discovery: https://www.npmjs.com/package/typescript
typescript_version := 6.0.2
# Discovery: https://www.npmjs.com/package/@typescript/native-preview
tsgo_version := 7.0.0-dev.20260411.1

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
	@~/.local/bin/npm uninstall -g @vtsls/language-server >/dev/null 2>&1 || true
	@~/.local/bin/npm install -g @typescript/native-preview@$(tsgo_version)
