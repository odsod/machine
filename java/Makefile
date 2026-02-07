name := java
# Policy: Track the latest LTS version available in Fedora repos.
version := 25

.PHONY: install-packages
install-packages:
	$(info [$(name)] Installing packages...)
	@sudo dnf install -y java-$(version)-openjdk-devel maven
