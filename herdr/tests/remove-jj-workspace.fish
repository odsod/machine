#!/usr/bin/env fish

set -g test_dir (path resolve (dirname (status filename)))
set -g remove_script (path resolve "$test_dir/../remove-jj-workspace")
set -g test_root (mktemp -d)
set -g search_root "$test_root/search"
set -g default_root "$search_root/repo"
set -g workspace_root "$search_root/workspaces"
set -g stub_bin "$test_root/bin"
set -g trash_root "$test_root/trash"
set -g test_home "$test_root/home"
set -g real_jj (command -s jj)
set -g real_fish (status fish-path)

function cleanup --on-event fish_exit
    rm -rf "$test_root"
end

function fail --argument-names message
    echo "FAIL: $message" >&2
    exit 1
end

function assert_path --argument-names path
    test -e "$path"; or fail "expected path to exist: $path"
end

function assert_no_path --argument-names path
    test -e "$path"; and fail "expected path to be absent: $path"
end

function add_workspace --argument-names name
    set -l path "$workspace_root/$name"
    jj -R "$default_root" workspace add --name "$name" "$path" >/dev/null
    or fail "could not create test workspace $name"
    jj -R "$path" bookmark set "$name" -r @ >/dev/null
    or fail "could not create test bookmark $name"
    printf '%s\n' "$path"
end

mkdir -p "$default_root" "$workspace_root" "$stub_bin" "$trash_root" "$test_home"
jj git init --colocate "$default_root" >/dev/null
or fail "could not create test repo"

printf '%s\n' \
    "#!$real_fish --no-config" \
    'if test "$argv[1]" = pane; and test "$argv[2]" = list' \
    '    printf "%s\n" "$HERDR_PANES_JSON"' \
    '    exit 0' \
    'end' \
    'exit 1' > "$stub_bin/herdr"

printf '%s\n' \
    "#!$real_fish --no-config" \
    'set -l input (cat | string collect)' \
    'test -n "$FZF_INPUT_LOG"; and printf "%s" "$input" > "$FZF_INPUT_LOG"' \
    'if test -n "$FZF_EXIT"' \
    '    exit "$FZF_EXIT"' \
    'end' \
    'string split "\n" -- "$input" | head -n1' > "$stub_bin/fzf"

printf '%s\n' \
    "#!$real_fish --no-config" \
    'test "$argv[1]" = trash; or exit 1' \
    'mkdir -p "$TEST_TRASH_ROOT"' \
    'mv "$argv[2]" "$TEST_TRASH_ROOT/"' > "$stub_bin/gio"

printf '%s\n' \
    "#!$real_fish --no-config" \
    'if test "$FAIL_JJ_FORGET" = 1' \
    '    set -l command_line (string join " " -- $argv)' \
    '    string match -q "*workspace forget*" -- "$command_line"; and exit 1' \
    'end' \
    'command "$REAL_JJ" $argv' > "$stub_bin/jj"

chmod +x "$stub_bin/herdr" "$stub_bin/fzf" "$stub_bin/gio" "$stub_bin/jj"

set -l empty_panes '{"result":{"panes":[]}}'
set -l system_path (string join : $PATH)
set -l common_env \
    "XDG_CONFIG_HOME=$test_home/config" \
    "PATH=$stub_bin:$system_path" \
    "REAL_JJ=$real_jj" \
    "REMOVE_JJ_WORKSPACE_ROOT=$search_root" \
    "TEST_TRASH_ROOT=$trash_root"

set -l feature_path (add_workspace feature)

env $common_env "HERDR_PANES_JSON=$empty_panes" FZF_EXIT=130 \
    "$real_fish" --no-config "$remove_script" >/dev/null
or fail "cancel should exit successfully"
assert_path "$feature_path"

set -l picker_log "$test_root/picker.log"
printf 'n\n' | env $common_env "HERDR_PANES_JSON=$empty_panes" \
    "FZF_INPUT_LOG=$picker_log" "$real_fish" --no-config "$remove_script" >/dev/null
or fail "declined confirmation should exit successfully"
assert_path "$feature_path"
awk -F '\t' '$5 == "default" { found = 1 } END { exit found ? 0 : 1 }' "$picker_log"
and fail "default workspace was offered for removal"

set -l open_panes (jq -nc --arg path "$feature_path" \
    '{result:{panes:[{cwd:$path,foreground_cwd:$path}]}}')
set -l open_output (env $common_env "HERDR_PANES_JSON=$open_panes" \
    "$real_fish" --no-config "$remove_script" 2>&1)
test $status -ne 0; or fail "open workspace removal should fail: $open_output"
string match -q '*Close the Herdr workspace*' -- "$open_output"
or fail "open workspace failure did not explain how to proceed"
assert_path "$feature_path"

printf 'y\n' | env $common_env "HERDR_PANES_JSON=$empty_panes" \
    "$real_fish" --no-config "$remove_script" >/dev/null
or fail "confirmed removal failed"
assert_no_path "$feature_path"
assert_path "$trash_root/feature"
jj --ignore-working-copy -R "$default_root" workspace root --name feature >/dev/null 2>&1
and fail "removed workspace is still registered"
jj --ignore-working-copy -R "$default_root" log -r 'bookmarks(exact:feature)' \
    --no-graph --limit 1 | string match -qr '.'
or fail "workspace bookmark was deleted"

set -l failure_path (add_workspace forget-failure)
set -l failure_output (printf 'y\n' | env $common_env \
    "HERDR_PANES_JSON=$empty_panes" FAIL_JJ_FORGET=1 \
    "$real_fish" --no-config "$remove_script" 2>&1)
test $status -ne 0; or fail "forget failure should return non-zero"
string match -q '*can be restored with: gio trash --list*' -- "$failure_output"
or fail "forget failure did not report recovery"
assert_no_path "$failure_path"
assert_path "$trash_root/forget-failure"
jj --ignore-working-copy -R "$default_root" workspace list -T 'self.name() ++ "\n"' \
    | string match -q forget-failure
or fail "failed forget should leave the jj workspace registered"

echo "remove-jj-workspace tests passed"
