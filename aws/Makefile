name := aws
# Discovery: https://raw.githubusercontent.com/aws/aws-cli/v2/CHANGELOG.rst
version := 2.34.10
archive := awscli-exe-linux-x86_64-$(version).zip
archive_url := https://awscli.amazonaws.com/$(archive)
sig_url := $(archive_url).sig
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)/$(version)
install_dir := $(HOME)/.local/share/odsod/machine/aws-cli
bin_dir := $(HOME)/.local/bin
fish_completion := $(HOME)/.config/fish/completions/aws.fish
install_marker := $(install_dir)/v2/$(version)/dist/aws

.PHONY: install
install: $(install_marker) $(fish_completion)

$(install_marker): $(data_dir)/aws/install $(data_dir)/$(archive).sig
	$(info [$(name)] Installing AWS CLI $(version)...)
	@mkdir -p "$(bin_dir)"
	@$(data_dir)/aws/install --update --install-dir "$(install_dir)" --bin-dir "$(bin_dir)"
	@test -x "$@"

$(data_dir)/aws/install: $(data_dir)/$(archive)
	$(info [$(name)] Extracting $(archive)...)
	@rm -rf "$(data_dir)/aws"
	@unzip -q "$(data_dir)/$(archive)" -d "$(data_dir)"
	@test -x "$@"

$(data_dir)/$(archive):
	$(info [$(name)] Downloading $(archive_url)...)
	@curl -fsSL "$(archive_url)" --create-dirs -o "$@"

$(data_dir)/$(archive).sig:
	$(info [$(name)] Downloading $(sig_url)...)
	@curl -fsSL "$(sig_url)" --create-dirs -o "$@"

.PHONY: $(fish_completion)
$(fish_completion): aws.fish
	$(info [$(name)] Symlinking $@...)
	@mkdir -p "$(dir $@)"
	@ln -fsT "$(abspath $<)" "$@"
