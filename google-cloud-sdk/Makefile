name := google-cloud-sdk
# Discovery: https://cloud.google.com/sdk/docs/install-sdk
version := 573.0.0
archive_url := https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-$(version)-linux-x86_64.tar.gz
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)
install_dir := $(data_dir)/$(version)/google-cloud-sdk

.PHONY: install
install: ~/.local/bin/gcloud ~/.local/bin/bq ~/.local/bin/gsutil

.PHONY: ~/.local/bin/gcloud
~/.local/bin/gcloud: $(install_dir)/bin/gcloud
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

.PHONY: ~/.local/bin/bq
~/.local/bin/bq: $(install_dir)/bin/gcloud
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(install_dir)/bin/bq $@

.PHONY: ~/.local/bin/gsutil
~/.local/bin/gsutil: $(install_dir)/bin/gcloud
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(install_dir)/bin/gsutil $@

$(install_dir)/bin/gcloud: $(data_dir)/$(version)/archive.tar.gz
	$(info [$(name)] Extracting $<...)
	@tar -C $(data_dir)/$(version) -xf $<
	@$(install_dir)/bin/gcloud components install alpha beta --quiet
	@touch $@

$(data_dir)/$(version)/archive.tar.gz:
	$(info [$(name)] Downloading $(archive_url)...)
	@curl $(archive_url) -fLo $@ --create-dirs
	@touch $@

.PHONY: discover
discover:
	@printf 'version=%s\n' "$$(curl -s \
		https://dl.google.com/dl/cloudsdk/channels/rapid/components-2.json \
		| jq -r '.version // "UNKNOWN"')"
