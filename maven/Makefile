name := maven
version := 3.9.6
archive_url := https://dlcdn.apache.org/maven/maven-3/$(version)/binaries/apache-maven-$(version)-bin.tar.gz
archive := build/$(version)/archive.tar.gz
cmd := build/$(version)/apache-maven-$(version)/bin/mvn
maven_home := build/$(version)/apache-maven-$(version)
symlink := ~/.local/share/odsod/machine/$(name)
environment := ~/.config/environment.d/10-odsod-machine-$(name).conf

.PHONY: all
all: $(symlink) $(environment)

.PHONY: $(environment)
$(environment): environment.conf
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: $(symlink)
$(symlink): $(maven_home)
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: $(maven_home)
$(maven_home): $(cmd)

$(cmd): $(archive)
	$(info [$(name)] Extracting $(archive)...)
	@tar -C $(dir $<) -xf $<
	@touch $@
	@chmod +x $@

$(archive):
	$(info [$(name)] Downloading $(archive_url)...)
	@curl $(archive_url) --create-dirs -Lo $@
	@touch $@
