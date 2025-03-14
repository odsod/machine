name := google-cloud-sdk

.PHONY: install-package
install-package: /etc/yum.repos.d/$(name).repo
	$(info [$(name)] Installing package...)
	@sudo dnf install -y google-cloud-sdk

/etc/yum.repos.d/$(name).repo: $(name).repo
	$(info [$(name)] Installing repo...)
	@sudo cp -f $< $@
	@dnf check-update
