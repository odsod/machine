name := endpoint-verification
packages_url := https://packages.cloud.google.com/apt/dists/endpoint-verification/main/binary-amd64/Packages
apt_base_url := https://packages.cloud.google.com/apt
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

latest_entry := $(shell curl -fsSL $(packages_url) | awk 'BEGIN { RS = ""; FS = "\n" } /(^|\n)Package: endpoint-verification(\n|$$)/ { version = ""; filename = ""; sha256 = ""; size = ""; for (i = 1; i <= NF; i++) { if ($$i ~ /^Version: /) version = substr($$i, 10); if ($$i ~ /^Filename: /) filename = substr($$i, 11); if ($$i ~ /^SHA256: /) sha256 = substr($$i, 9); if ($$i ~ /^Size: /) size = substr($$i, 7); } print version "\t" filename "\t" sha256 "\t" size }' | sort -V | tail -1)
version := $(word 1,$(latest_entry))
filename := $(word 2,$(latest_entry))
sha256 := $(word 3,$(latest_entry))
package_url := $(apt_base_url)/$(filename)
version_dir := $(data_dir)/$(version)
extract_dir := $(version_dir)/extract
package := $(version_dir)/package.deb
extract_stamp := $(extract_dir)/.extracted
manifest := com.google.endpoint_verification.api_helper.json
service := endpoint-verification.service
install_prefix := /opt/google/endpoint-verification

.PHONY: all
all: install verify

.PHONY: install
install: install-packages install-files enable-service

.PHONY: install-packages
install-packages:
	$(info [$(name)] Installing extraction dependencies...)
	@sudo dnf install -y -q binutils gzip tar util-linux

.PHONY: install-files
install-files: $(extract_stamp) device_state.sh
	$(info [$(name)] Installing helper files...)
	@sudo install -d -m 0755 \
		$(install_prefix)/bin \
		$(install_prefix)/var/lib \
		/etc/opt/chrome/native-messaging-hosts \
		/lib/systemd/system
	@if command -v selinuxenabled >/dev/null && selinuxenabled; then \
		sudo chcon -t var_lib_t $(install_prefix)/var $(install_prefix)/var/lib; \
	fi
	@sudo install -m 0755 \
		$(extract_dir)/opt/google/endpoint-verification/bin/apihelper \
		$(install_prefix)/bin/apihelper
	@sudo install -m 0755 device_state.sh $(install_prefix)/bin/device_state.sh
	@sudo install -m 0644 \
		$(extract_dir)/etc/opt/chrome/native-messaging-hosts/$(manifest) \
		/etc/opt/chrome/native-messaging-hosts/$(manifest)
	@sudo install -m 0644 \
		$(extract_dir)/lib/systemd/system/$(service) \
		/lib/systemd/system/$(service)

.PHONY: enable-service
enable-service: install-files
	$(info [$(name)] Enabling systemd service...)
	@sudo systemctl daemon-reload
	@sudo systemctl enable $(service)
	@sudo systemctl restart $(service)

$(extract_stamp): $(package)
	$(info [$(name)] Extracting $(package)...)
	@rm -rf $(extract_dir)
	@mkdir -p $(extract_dir)
	@cd $(extract_dir) && ar x $(abspath $<)
	@tar -C $(extract_dir) -xzf $(extract_dir)/data.tar.gz
	@touch $@

$(package):
	$(info [$(name)] Downloading $(package_url)...)
	@test -n "$(version)" || { echo "[$(name)] ERROR: no package version found"; exit 1; }
	@mkdir -p $(dir $@)
	@curl -fsSL $(package_url) -o $@
	@printf '%s  %s\n' "$(sha256)" "$@" | sha256sum -c

.PHONY: verify
verify:
	$(info [$(name)] Verifying device state output...)
	@printf '%s\n' '--- device_state.sh init ---'
	@sudo $(install_prefix)/bin/device_state.sh init
	@printf '%s\n' '--- device_state.sh ---'
	@$(install_prefix)/bin/device_state.sh

.PHONY: discover
discover:
	@printf 'version=%s\n' "$(version)"
	@printf 'sha256=%s\n' "$(sha256)"
	@printf 'filename=%s\n' "$(filename)"
