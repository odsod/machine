name := lua

# Discovery: https://github.com/LuaLS/lua-language-server/releases/latest
lua_ls_version := 3.17.1
lua_ls_archive := lua-language-server-$(lua_ls_version)-linux-x64.tar.gz
lua_ls_url := https://github.com/LuaLS/lua-language-server/releases/download/$(lua_ls_version)/$(lua_ls_archive)

# Discovery: https://github.com/JohnnyMorganz/StyLua/releases/latest
stylua_version := v2.4.0
stylua_archive := stylua-linux-x86_64.zip
stylua_url := https://github.com/JohnnyMorganz/StyLua/releases/download/$(stylua_version)/$(stylua_archive)

data_dir := $(HOME)/.local/share/odsod/machine/data/$(name)

.PHONY: all
all: \
	~/.local/bin/lua-language-server \
	~/.local/bin/stylua

.PHONY: ~/.local/bin/lua-language-server
~/.local/bin/lua-language-server: $(data_dir)/lua-ls/$(lua_ls_version)/bin/lua-language-server
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

$(data_dir)/lua-ls/$(lua_ls_version)/bin/lua-language-server: $(data_dir)/lua-ls/$(lua_ls_version)/archive.tar.gz
	$(info [$(name)] Extracting $(lua_ls_archive)...)
	@mkdir -p $(dir $@)
	@tar -C $(data_dir)/lua-ls/$(lua_ls_version) -xf $<
	@touch $@

$(data_dir)/lua-ls/$(lua_ls_version)/archive.tar.gz:
	$(info [$(name)] Downloading $(lua_ls_url)...)
	@mkdir -p $(dir $@)
	@curl -L $(lua_ls_url) -o $@

.PHONY: ~/.local/bin/stylua
~/.local/bin/stylua: $(data_dir)/stylua/$(stylua_version)/stylua
	$(info [$(name)] Symlinking $@...)
	@mkdir -p $(dir $@)
	@ln -fsT $(abspath $<) $@

$(data_dir)/stylua/$(stylua_version)/stylua: $(data_dir)/stylua/$(stylua_version)/archive.zip
	$(info [$(name)] Extracting $(stylua_archive)...)
	@mkdir -p $(dir $@)
	@unzip -q -o $< -d $(dir $@)
	@chmod +x $@

$(data_dir)/stylua/$(stylua_version)/archive.zip:
	$(info [$(name)] Downloading $(stylua_url)...)
	@mkdir -p $(dir $@)
	@curl -L $(stylua_url) -o $@
