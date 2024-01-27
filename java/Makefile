name := java
environment := ~/.config/environment.d/10-$(name).conf

.PHONY: all
all: install-packages $(environment)

.PHONY: install-packages
install-packages:
	$(info [$(name)] Installing packages...)
	@sudo apt-get install -y \
		openjdk-21-jdk \
		| sed -e "s/^/[$(name):$@] /"

.PHONY: $(environment)
$(environment): environment.conf
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@
