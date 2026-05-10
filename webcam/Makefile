name := webcam

.PHONY: install
install: install-packages install-flatpak

.PHONY: install-packages
install-packages:
	$(info [$(name)] Installing packages...)
	@sudo dnf install -y v4l-utils

.PHONY: install-flatpak
install-flatpak:
	$(info [$(name)] Installing cameractrls...)
	@flatpak install -y flathub hu.irl.cameractrls
