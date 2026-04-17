name := yaml

# Discovery: https://www.npmjs.com/package/yaml-language-server
yamlls_version := 1.22.0

.PHONY: all
all: install

.PHONY: install
install:
	@$(MAKE) -C ../nodejs ~/.local/bin/npm
	@$(MAKE) npm-packages

.PHONY: npm-packages
npm-packages:
	$(info [$(name)] Installing yaml-language-server...)
	@~/.local/bin/npm install -g yaml-language-server@$(yamlls_version)
