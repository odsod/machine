name := python

.PHONY: install-packages
install-packages:
	$(info [$(name)] Installing packages...)
	@sudo apt-get install -y \
		python3-pip \
		python3-venv \
		| sed -e "s/^/[$(name):$@] /"
