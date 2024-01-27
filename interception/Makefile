SHELL := /usr/bin/env bash

.PHONY: all
all: \
	install-deps \
	install-udevmon \
	install-tools \
	install-caps2esc \
	install-space2meta \
	start-udevmon

.PHONY: install-deps
install-deps:
	$(info [$(name)] Installing deps...)
	@sudo apt install -y cmake clang libyaml-cpp-dev libevdev-dev libudev-dev

/etc/systemd/system/udevmon.service: udevmon.service
	$(info [$(name)] Installing $@...)
	sudo cp -f $< $@

/etc/udevmon.yaml: udevmon.yaml
	$(info [$(name)] Installing $@...)
	sudo cp -f $< $@

.PHONY: install-udevmon
install-udevmon: /etc/udevmon.yaml /etc/systemd/system/udevmon.service

.PHONY: start-udevmon
start-udevmon:
	$(info [$(name)] Starting udevmon service $@...)
	@sudo systemctl enable udevmon.service
	@sudo systemctl start udevmon.service

.PHONY: install-tools
install-tools:
	$(info [$(name)] Installing tools...)
	@cd tools && \
		mkdir -p build && \
		cd build && \
		cmake .. && \
		make && \
		sudo make install

.PHONY: install-caps2esc
install-caps2esc:
	$(info [$(name)] Installing caps2esc...)
	@cd plugins/caps2esc && \
		mkdir -p build && \
		cd build && \
		cmake .. && \
		make && \
		sudo make install

.PHONY: install-space2meta
install-space2meta:
	$(info [$(name)] Installing space2meta...)
	@cd plugins/space2meta && \
		mkdir -p build && \
		cd build && \
		cmake .. && \
		make && \
		sudo make install
