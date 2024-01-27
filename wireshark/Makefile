name := wireshark
group := wireshark
user := $(shell whoami)

.PHONY: all
all: configure-debconf install-package configure-group

.PHONY: configure-group
configure-group:
	$(info [$(name)] Configuring group...)
	@sudo groupadd -f $(group)
	@sudo usermod -aG $(group) $(user)

.PHONY: install-package
install-package: configure-debconf
	$(info [$(name)] Installing package...)
	@sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
		wireshark \
		| sed -e "s/^/[$(name):$@] /"

.PHONY: configure-debconf
configure-debconf:
	$(info [$(name)] Configuring debconf...)
	@echo "wireshark-common wireshark-common/install-setuid boolean true" \
		| sudo debconf-set-selections \
		| sed -e "s/^/[$(name):$@] /"
