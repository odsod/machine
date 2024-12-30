name := proton-vpn
version := 1.0.6
repo_deb := build/$(version)/protonvpn-stable-release.deb
repo_deb_url := https://repo.protonvpn.com/debian/dists/stable/main/binary-all/protonvpn-stable-release_$(version)_all.deb

.PHONY: install-package
install-package: install-repo-deb
	$(info [$(name)] Installing package...)
	@sudo apt-get install -y \
		proton-vpn-gnome-desktop \
		| sed -e "s/^/[$(name):$@] /"

.PHONY: install-repo-deb
install-repo-deb: $(repo_deb)
	$(info [$(name)] Installing $(repo_deb)...)
	@sudo dpkg -i $<
	@sudo apt update

$(repo_deb):
	$(info [$(name)] Downloading $(repo_deb)...)
	@curl $(repo_deb_url) --create-dirs -Lo $@
	@touch $@
