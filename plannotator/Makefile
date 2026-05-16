name := plannotator
# Discovery: https://github.com/backnotprop/plannotator/releases/latest
version := 0.19.17
binary_url := https://github.com/backnotprop/plannotator/releases/download/v$(version)/plannotator-linux-x64
data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)/$(version)
active_dir := $(HOME)/.local/share/odsod/machine/$(name)
marketplace_dir := $(HOME)/.claude/plugins/marketplaces/$(name)
cache_dir := $(HOME)/.claude/plugins/cache/$(name)/$(name)/$(version)
plugin_marker := $(cache_dir)/.installed

.PHONY: install
install: ~/.local/bin/$(name) ~/.local/bin/$(name)-browser $(plugin_marker)

~/.local/bin/$(name): $(name) $(active_dir)
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

~/.local/bin/$(name)-browser: $(name)-browser
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

$(data_dir)/$(name):
	$(info [$(name)] Downloading $(binary_url)...)
	@curl -fsSL "$(binary_url)" --create-dirs -o "$@"
	@chmod +x "$@"

$(active_dir): $(data_dir)/$(name)
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT "$(data_dir)" "$@"

# Claude Code plugin — replicates /plugin marketplace add + /plugin install
$(plugin_marker): $(marketplace_dir)/v$(version).tag
	$(info [$(name)] Installing Claude Code plugin...)
	@rm -rf "$(cache_dir)"
	@mkdir -p "$(dir $(cache_dir))"
	@mkdir -p "$(HOME)/.claude/plugins"
	@test -s "$(HOME)/.claude/plugins/known_marketplaces.json" || printf '{}\n' > "$(HOME)/.claude/plugins/known_marketplaces.json"
	@test -s "$(HOME)/.claude/plugins/installed_plugins.json" || printf '{"plugins":{}}\n' > "$(HOME)/.claude/plugins/installed_plugins.json"
	@cp -r "$(marketplace_dir)/apps/hook" "$(cache_dir)"
	@jq --arg loc "$(marketplace_dir)" \
	    '.plannotator = {"source": {"source": "github", "repo": "backnotprop/plannotator"}, "installLocation": $$loc, "lastUpdated": "$(shell date -u +%Y-%m-%dT%H:%M:%S.000Z)"}' \
	    "$(HOME)/.claude/plugins/known_marketplaces.json" > "$(HOME)/.claude/plugins/known_marketplaces.json.tmp" \
	    && mv "$(HOME)/.claude/plugins/known_marketplaces.json.tmp" "$(HOME)/.claude/plugins/known_marketplaces.json"
	@jq --arg path "$(cache_dir)" --arg ver "$(version)" \
	    '.plugins = (.plugins // {}) | .plugins["plannotator@plannotator"] = [{"scope": "user", "installPath": $$path, "version": $$ver, "installedAt": "$(shell date -u +%Y-%m-%dT%H:%M:%S.000Z)", "lastUpdated": "$(shell date -u +%Y-%m-%dT%H:%M:%S.000Z)"}]' \
	    "$(HOME)/.claude/plugins/installed_plugins.json" > "$(HOME)/.claude/plugins/installed_plugins.json.tmp" \
	    && mv "$(HOME)/.claude/plugins/installed_plugins.json.tmp" "$(HOME)/.claude/plugins/installed_plugins.json"
	@jq '.enabledPlugins = (.enabledPlugins // {}) | .enabledPlugins["plannotator@plannotator"] = true' \
	    "$(HOME)/.claude/settings.json" > "$(HOME)/.claude/settings.json.tmp" \
	    && mv "$(HOME)/.claude/settings.json.tmp" "$(HOME)/.claude/settings.json"
	@touch "$@"

# Sentinel file ensures re-clone when version changes
$(marketplace_dir)/v$(version).tag:
	$(info [$(name)] Cloning marketplace repo at v$(version)...)
	@rm -rf "$(marketplace_dir)"
	@git clone --depth 1 --branch "v$(version)" \
	    https://github.com/backnotprop/plannotator "$(marketplace_dir)"
	@touch "$@"
