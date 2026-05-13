name := google-cloud-sdk
# Discovery: https://cloud.google.com/sdk/docs/install-sdk
version := 568.0.0
archive_url := https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-$(version)-linux-x86_64.tar.gz
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)
install_dir := $(data_dir)/$(version)/google-cloud-sdk

.PHONY: ~/.local/bin/gcloud
~/.local/bin/gcloud: $(install_dir)/bin/gcloud
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

$(install_dir)/bin/gcloud: $(data_dir)/$(version)/archive.tar.gz
	$(info [$(name)] Extracting $<...)
	@tar -C $(data_dir)/$(version) -xf $<
	@$(install_dir)/bin/gcloud components install alpha beta --quiet
	@touch $@

$(data_dir)/$(version)/archive.tar.gz:
	$(info [$(name)] Downloading $(archive_url)...)
	@curl $(archive_url) -fLo $@ --create-dirs
	@touch $@
