name := zoom
# Discovery: https://support.zoom.com/hc/en/article?id=zm_kb&sysparm_article=KB0061222
version := 6.7.5.6891
package_url := https://zoom.us/client/$(version)/zoom_x86_64.rpm
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: install-package
install-package: $(data_dir)/$(version)/package.rpm
	$(info [$(name)] Installing package...)
	@if ! rpm -q zoom >/dev/null 2>&1; then \
		sudo dnf install -y $<; \
	fi

$(data_dir)/$(version)/package.rpm:
	$(info [$(name)] Downloading package...)
	@curl $(package_url) --create-dirs -Lo $@
	@touch $@
