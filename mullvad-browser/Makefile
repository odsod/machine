name := mullvad-browser

.PHONY: install-package
install-package:
	@if [ ! -f /etc/yum.repos.d/mullvad.repo ]; then \
		sudo dnf config-manager addrepo --overwrite --from-repofile=https://repository.mullvad.net/rpm/stable/mullvad.repo; \
	fi
	@sudo dnf install -y mullvad-browser
