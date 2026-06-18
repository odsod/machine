name := 1password

.PHONY: install
install: install-repo install-package

.PHONY: install-repo
install-repo:
	$(info [$(name)] Installing repository...)
	@if [ ! -f /etc/yum.repos.d/1password.repo ]; then \
		sudo rpm --import https://downloads.1password.com/linux/keys/1password.asc; \
		printf '%s\n' \
			'[1password]' \
			'name=1Password Stable Channel' \
			'baseurl=https://downloads.1password.com/linux/rpm/stable/$$basearch' \
			'enabled=1' \
			'gpgcheck=1' \
			'repo_gpgcheck=1' \
			'gpgkey=https://downloads.1password.com/linux/keys/1password.asc' \
			| sudo tee /etc/yum.repos.d/1password.repo > /dev/null; \
	fi

.PHONY: install-package
install-package: install-repo
	$(info [$(name)] Installing package...)
	@sudo dnf install -y 1password
