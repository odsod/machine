name := gh-cli

.PHONY: install-package
install-package: /etc/yum.repos.d/$(name).repo
	$(info [$(name)] Installing package...)
	@sudo dnf install -y --repo gh-cli gh

/etc/yum.repos.d/$(name).repo:
	$(info [$(name)] Adding $@...)
	@sudo dnf config-manager addrepo --overwrite --from-repofile=https://cli.github.com/packages/rpm/gh-cli.repo
	@sudo dnf check-update
