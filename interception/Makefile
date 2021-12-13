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
	sudo apt install -y cmake clang libyaml-cpp-dev libevdev-dev libudev-dev

/etc/systemd/system/udevmon.service: udevmon.service
	sudo cp -f $< $@

/etc/udevmon.yaml: udevmon.yaml
	sudo cp -f $< $@

.PHONY: install-udevmon
install-udevmon: /etc/udevmon.yaml /etc/systemd/system/udevmon.service

.PHONY: start-udevmon
start-udevmon:
	sudo systemctl enable udevmon.service
	sudo systemctl start udevmon.service

.PHONY: install-tools
install-tools:
	cd tools && \
		mkdir -p build && \
		cd build && \
		cmake .. && \
		make && \
		sudo make install

.PHONY: install-caps2esc
install-caps2esc:
	cd plugins/caps2esc && \
		mkdir -p build && \
		cd build && \
		cmake .. && \
		make && \
		sudo make install

.PHONY: install-space2meta
install-space2meta:
	cd plugins/space2meta && \
		mkdir -p build && \
		cd build && \
		cmake .. && \
		make && \
		sudo make install
