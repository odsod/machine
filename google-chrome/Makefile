name := google-chrome

.PHONY: install-packages
install-packages:
	$(info [$(name)] Installing packages...)
	@sudo dnf config-manager setopt google-chrome.enabled=1
	@sudo dnf install -y google-chrome-stable
