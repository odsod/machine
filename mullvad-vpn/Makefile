name := mullvad-vpn

.PHONY: install-package
install-package:
	@sudo dnf config-manager addrepo --from-repofile=https://repository.mullvad.net/rpm/stable/mullvad.repo
	@sudo dnf install -y mullvad-vpn
