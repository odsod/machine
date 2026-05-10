name := keys
binary := odsod-keys
src := odsod-keys.c
install_path := /usr/local/bin/$(binary)
service := $(binary).service
service_path := /etc/systemd/system/$(service)

.PHONY: install
install: install-packages $(install_path) $(service_path) enable-service

.PHONY: install-packages
install-packages:
	$(info [$(name)] Installing build dependencies...)
	@sudo dnf install -y -q gcc kernel-headers

$(install_path): $(src)
	$(info [$(name)] Building and installing $(binary)...)
	@gcc -O2 -Wall -Wextra -Werror -o $(binary) $<
	@sudo install -m 0755 $(binary) $@
	@rm $(binary)

$(service_path): $(service)
	$(info [$(name)] Installing service...)
	@sudo cp -f $< $@
	@sudo systemctl daemon-reload

.PHONY: enable-service
enable-service: $(install_path) $(service_path)
	$(info [$(name)] Enabling service...)
	@sudo systemctl enable --now $(service)

.PHONY: build
build:
	$(info [$(name)] Building $(binary)...)
	@gcc -O2 -Wall -Wextra -Werror -o $(binary) $(src)
	@rm $(binary)

.PHONY: deploy
deploy: $(install_path) restart

.PHONY: restart
restart:
	$(info [$(name)] Restarting service...)
	@sudo systemctl restart $(service)

.PHONY: stop
stop:
	$(info [$(name)] Stopping service...)
	@sudo systemctl stop $(service)

.PHONY: status
status:
	@systemctl status $(service)

.PHONY: log
log:
	@journalctl -u $(service) -f

.PHONY: uninstall
uninstall:
	$(info [$(name)] Uninstalling...)
	@sudo systemctl disable --now $(service) 2>/dev/null || true
	@sudo rm -f $(install_path) $(service_path)
	@sudo systemctl daemon-reload
