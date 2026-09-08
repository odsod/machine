#!/usr/bin/env fish

set -g test_dir (path resolve (dirname (status filename)))
set -g start_script (path resolve "$test_dir/../start-workspace")
set -g test_root (mktemp -d)
set -g real_fish (status fish-path)
# Resolve past the mise shim: under the stubbed HOME the shim cannot find its
# tool and falls back to `jj` on PATH, which is the stub, recursing forever.
set -g real_jj (mise which jj 2>/dev/null)
test -n "$real_jj"; or set -g real_jj (command -s jj)

function cleanup --on-event fish_exit
    rm -rf "$test_root"
end

function fail --argument-names message
    echo "FAIL: $message" >&2
    exit 1
end

function write_stubs --argument-names home
    set -l stub_bin "$home/.local/bin"
    mkdir -p "$stub_bin" "$home/.config"

    printf '%s\n' \
        "#!$real_fish --no-config" \
        'set -l count 0' \
        'test -f "$FZF_COUNT_FILE"; and read count < "$FZF_COUNT_FILE"' \
        'set count (math "$count + 1")' \
        'printf "%s\n" "$count" > "$FZF_COUNT_FILE"' \
        'set -l prompt_arg ""' \
        'for arg in $argv' \
        '    if string match -q -- "--prompt=*" "$arg"' \
        '        set prompt_arg (string replace -- "--prompt=" "" "$arg")' \
        '    end' \
        end \
        'test -n "$FZF_LOG"; and echo "$prompt_arg" >> "$FZF_LOG"' \
        'switch "$prompt_arg"' \
        '    case "Machine> "' \
        '        if test -n "$FZF_MACHINE_CHOICE"' \
        '            echo "$FZF_MACHINE_CHOICE"' \
        '        else' \
        '            echo Local' \
        '        end' \
        '    case "Space> "' \
        '        echo Workspace' \
        '    case "Workspace> "' \
        '        head -n1' \
        '    case "Bookmark> "' \
        '        set -l bm_lines (cat)' \
        '        test -n "$FZF_BOOKMARK_LOG"; and printf "%s\n" $bm_lines > "$FZF_BOOKMARK_LOG"' \
        '        if test "$FZF_BOOKMARK_MODE" = typed' \
        '            echo typed' \
        '        else' \
        '            echo "$bm_lines[1]"' \
        '        end' \
        '    case "Agent> "' \
        '        if test -n "$FZF_AGENT_CHOICE"' \
        '            echo "$FZF_AGENT_CHOICE"' \
        '        else' \
        '            echo codex' \
        '        end' \
        '    case "*"' \
        '        exit 2' \
        end >"$stub_bin/fzf"

    printf '%s\n' \
        "#!$real_fish --no-config" \
        'printf "%s\n" (string join " " -- $argv) >> "$HERDR_LOG"' \
        'set -l command_line (string join " " -- $argv)' \
        'switch "$command_line"' \
        '    case "machine list --json"' \
        '        if test -n "$HERDR_MACHINES_JSON"' \
        '            printf "%s\n" "$HERDR_MACHINES_JSON"' \
        '        else' \
        '            printf "[]\n"' \
        '        end' \
        '    case "workspace list"' \
        '        if test "$HERDR_EXISTING" = 1' \
        '            printf "{\"result\":{\"workspaces\":[{\"label\":\"repo/feature\",\"workspace_id\":\"wExisting\"}]}}\\n"' \
        '        else' \
        '            printf "{\"result\":{\"workspaces\":[]}}\\n"' \
        '        end' \
        '    case "pane list --workspace wExisting"' \
        '        jq -nc --arg cwd "$EXPECTED_CWD" '\''{result:{panes:[{cwd:$cwd,foreground_cwd:$cwd}]}}'\''' \
        '    case "workspace create *"' \
        '        printf "{\"result\":{\"workspace\":{\"workspace_id\":\"wCase\"},\"root_pane\":{\"pane_id\":\"wCase:p1\"}}}\\n"' \
        '    case "workspace focus wExisting" "agent start *"' \
        '        printf "{\"result\":{\"type\":\"ok\"}}\\n"' \
        '    case "*"' \
        '        exit 1' \
        end >"$stub_bin/herdr"

    printf '%s\n' \
        "#!$real_fish --no-config" \
        'command "$REAL_JJ" $argv' >"$stub_bin/jj"

    printf '%s\n' \
        "#!$real_fish --no-config" \
        'printf "%s\n" (string join " " -- $argv) >> "$SSH_LOG"' \
        'exit 0' >"$stub_bin/ssh"

    printf '%s\n' "#!$real_fish --no-config" 'exit 0' >"$stub_bin/codex"
    printf '%s\n' "#!$real_fish --no-config" 'exit 0' >"$stub_bin/claude"
    printf '%s\n' "#!$real_fish --no-config" 'exit 0' >"$stub_bin/cursor"
    printf '%s\n' "#!$real_fish --no-config" 'exit 0' >"$stub_bin/agy"
    printf '%s\n' "#!$real_fish --no-config" 'exit 0' >"$stub_bin/pi"
    printf '%s\n' "#!$real_fish --no-config" 'exit 1' >"$stub_bin/timeout"
    chmod +x "$stub_bin/fzf" "$stub_bin/herdr" "$stub_bin/jj" \
        "$stub_bin/ssh" "$stub_bin/codex" "$stub_bin/claude" \
        "$stub_bin/cursor" "$stub_bin/agy" "$stub_bin/pi" "$stub_bin/timeout"
end

function setup_case --argument-names name
    set -g case_home "$test_root/$name/home"
    set -g case_repo "$case_home/Code/github.com/acme/repo"
    mkdir -p "$case_repo"
    write_stubs "$case_home"
    jj git init --colocate "$case_repo" >/dev/null
    or fail "could not initialize launcher test repo"
end

function run_launcher --argument-names home repo mode existing expected_cwd extra_args
    set -l count_file "$home/fzf-count"
    set -l herdr_log "$home/herdr.log"
    set -l ssh_log "$home/ssh.log"
    set -l fzf_log "$home/fzf.log"
    set -l bookmark_log "$home/bookmark.log"
    set -l system_path (string join : $PATH)
    rm -f "$count_file" "$herdr_log" "$ssh_log" "$fzf_log" "$bookmark_log"

    set -l original_dir "$PWD"
    cd "$home"
    env \
        "HOME=$home" \
        "XDG_CONFIG_HOME=$home/.config" \
        "PATH=$home/.local/bin:$system_path" \
        "REAL_JJ=$real_jj" \
        "FZF_COUNT_FILE=$count_file" \
        "FZF_BOOKMARK_MODE=$mode" \
        "HERDR_EXISTING=$existing" \
        "EXPECTED_CWD=$expected_cwd" \
        "HERDR_LOG=$herdr_log" \
        "SSH_LOG=$ssh_log" \
        "FZF_LOG=$fzf_log" \
        "FZF_BOOKMARK_LOG=$bookmark_log" \
        "HERDR_MACHINES_JSON=$HERDR_MACHINES_JSON" \
        "FZF_MACHINE_CHOICE=$FZF_MACHINE_CHOICE" \
        "FZF_AGENT_CHOICE=$FZF_AGENT_CHOICE" \
        HERDR_PANE_ID= \
        "$real_fish" --no-config "$start_script" (string split " " -- "$extra_args") >/dev/null
    set -l launcher_status $status
    cd "$original_dir"
    test $launcher_status -eq 0; or fail "launcher failed in $mode mode"

    set -g launcher_log "$herdr_log"
    set -g launcher_ssh_log "$ssh_log"
    set -g launcher_fzf_log "$fzf_log"
    set -g launcher_bookmark_log "$bookmark_log"
end

setup_case existing
set -l existing_home "$case_home"
set -l existing_repo "$case_repo"
jj -R "$existing_repo" bookmark set feature -r @ >/dev/null
set -l existing_path "$existing_home/Workspaces/github.com/acme/repo/feature"
run_launcher "$existing_home" "$existing_repo" existing 0 "$existing_path"
set -l existing_log "$launcher_log"

test (jj --ignore-working-copy -R "$existing_repo" workspace root --name feature) = "$existing_path"
or fail "existing bookmark selection created the wrong workspace"
string match -q '*Machine>*' (string collect < "$launcher_fzf_log")
or fail "launcher did not prompt for machine when only local"
string match -q '*workspace create*--label repo/feature*' (string collect < "$existing_log")
or fail "launcher did not create the existing bookmark workspace"
string match -q '*agent start codex-wcase --kind codex --pane wCase:p1*' \
    (string collect < "$existing_log")
or fail "launcher did not use returned Herdr IDs for agent startup"
test -f "$existing_home/.codex/config.toml"
or fail "launcher did not create codex config"
grep -qF "[projects.\"$existing_path\"]" "$existing_home/.codex/config.toml"
or fail "launcher did not trust workspace in codex config"

run_launcher "$existing_home" "$existing_repo" existing 1 "$existing_path"
set existing_log "$launcher_log"
string match -q '*workspace focus wExisting*' (string collect < "$existing_log")
or fail "launcher did not focus the matching label and cwd"
string match -q '*workspace create*' (string collect < "$existing_log")
and fail "launcher created a duplicate matching workspace"

setup_case typed
set -l typed_home "$case_home"
set -l typed_repo "$case_repo"
set -l typed_path "$typed_home/Workspaces/github.com/acme/repo/typed"
run_launcher "$typed_home" "$typed_repo" typed 0 "$typed_path"
test (jj --ignore-working-copy -R "$typed_repo" workspace root --name typed) = "$typed_path"
or fail "typed bookmark selection created the wrong workspace"

# --- Auto-trust harness tests ---

for agent in claude cursor agy pi
    setup_case "trust_$agent"
    set -l t_home "$case_home"
    set -l t_repo "$case_repo"
    jj -R "$t_repo" bookmark set feature -r @ >/dev/null
    set -l t_path "$t_home/Workspaces/github.com/acme/repo/feature"
    set -g FZF_AGENT_CHOICE "$agent"
    run_launcher "$t_home" "$t_repo" existing 0 "$t_path"
    set -l t_log "$launcher_log"

    switch "$agent"
        case claude
            test -f "$t_home/.claude.json"
            or fail "claude trust file not created"
            jq -e --arg p "$t_path" '.projects[$p].hasTrustDialogAccepted == true' "$t_home/.claude.json" >/dev/null
            or fail "claude trust entry missing"
        case cursor
            set -l slug (echo "$t_path" | string replace -r '^/' '' | string replace -ra '[^a-zA-Z0-9]+' '-')
            test -f "$t_home/.cursor/projects/$slug/.workspace-trusted"
            or fail "cursor workspace-trusted file not created"
            jq -e --arg p "$t_path" '.workspacePath == $p' "$t_home/.cursor/projects/$slug/.workspace-trusted" >/dev/null
            or fail "cursor workspacePath mismatch"
            string match -q '*agent start cursor-wcase --kind cursor --pane wCase:p1 -- --trust*' \
                (string collect < "$t_log")
            or fail "cursor agent not started with --trust flag"
        case agy
            test -f "$t_home/.gemini/antigravity-cli/settings.json"
            or fail "agy settings file not created"
            jq -e --arg p "$t_path" '(.trustedWorkspaces // []) | index($p) != null' "$t_home/.gemini/antigravity-cli/settings.json" >/dev/null
            or fail "agy trustedWorkspaces missing path"
        case pi
            test -f "$t_home/.pi/agent/trust.json"
            or fail "pi trust.json not created"
            jq -e --arg p "$t_path" '.[$p] == true' "$t_home/.pi/agent/trust.json" >/dev/null
            or fail "pi trust entry missing"
    end
end
set -e FZF_AGENT_CHOICE

# --- Remote machine tests ---

setup_case remote_default
set -g HERDR_MACHINES_JSON '[{"id":"m1","label":"remote-box","target":"remote.lan","session":"default","enabled":true}]'
set -g FZF_MACHINE_CHOICE "remote-box"
run_launcher "$case_home" "$case_repo" existing 0 "$case_home/dummy"
test -f "$launcher_ssh_log"
or fail "ssh was not invoked for remote machine"
string match -q -- '*-q -t remote.lan start-workspace --local*' (string collect < "$launcher_ssh_log")
or fail "ssh was not called with expected target and command"

setup_case remote_custom_session
set -g HERDR_MACHINES_JSON '[{"id":"m2","label":"custom-box","target":"custom.lan","session":"work","enabled":true}]'
set -g FZF_MACHINE_CHOICE "custom-box"
run_launcher "$case_home" "$case_repo" existing 0 "$case_home/dummy"
string match -q -- '*-q -t custom.lan env HERDR_SESSION=work start-workspace --local*' (string collect < "$launcher_ssh_log")
or fail "ssh was not called with session environment variable"

setup_case remote_pick_local
set -g HERDR_MACHINES_JSON '[{"id":"m1","label":"remote-box","target":"remote.lan","session":"default","enabled":true}]'
set -g FZF_MACHINE_CHOICE "Local"
jj -R "$case_repo" bookmark set feature -r @ >/dev/null
set -l local_pick_path "$case_home/Workspaces/github.com/acme/repo/feature"
run_launcher "$case_home" "$case_repo" existing 0 "$local_pick_path"
test ! -f "$launcher_ssh_log"
or fail "ssh should not have been invoked when picking Local"
string match -q '*workspace create*--label repo/feature*' (string collect < "$launcher_log")
or fail "launcher did not create workspace locally after picking Local"

setup_case skip_machine_flag
set -g HERDR_MACHINES_JSON '[{"id":"m1","label":"remote-box","target":"remote.lan","session":"default","enabled":true}]'
set -g FZF_MACHINE_CHOICE "invalid-should-not-be-called"
jj -R "$case_repo" bookmark set feature -r @ >/dev/null
set -l flag_pick_path "$case_home/Workspaces/github.com/acme/repo/feature"
run_launcher "$case_home" "$case_repo" existing 0 "$flag_pick_path" "--local"
test ! -f "$launcher_ssh_log"
or fail "ssh should not have been invoked with --local flag"
if test -f "$launcher_fzf_log"
    string match -q '*Machine>*' (string collect < "$launcher_fzf_log")
    and fail "launcher prompted for machine when --local flag was passed"
end
string match -q '*workspace create*--label repo/feature*' (string collect < "$launcher_log")
or fail "launcher did not create workspace locally with --local flag"

setup_case machine_arg_remote
set -g HERDR_MACHINES_JSON '[{"id":"m1","label":"remote-box","target":"remote.lan","session":"default","enabled":true}]'
set -g FZF_MACHINE_CHOICE "invalid-should-not-be-called"
run_launcher "$case_home" "$case_repo" existing 0 "$case_home/dummy" "--machine remote-box"
test -f "$launcher_ssh_log"
or fail "ssh was not invoked with --machine flag"
if test -f "$launcher_fzf_log"
    string match -q '*Machine>*' (string collect < "$launcher_fzf_log")
    and fail "launcher prompted for machine when --machine flag was passed"
end
string match -q -- '*-q -t remote.lan start-workspace --local*' (string collect < "$launcher_ssh_log")
or fail "ssh was not called with expected target and command when using --machine"

set -e HERDR_MACHINES_JSON
set -e FZF_MACHINE_CHOICE

# --- Age sorting test ---

setup_case sort_by_age
env GIT_COMMITTER_DATE="2020-01-01T00:00:00Z" git -C "$case_repo" commit --allow-empty -m "old local" --date "2020-01-01T00:00:00Z" >/dev/null 2>&1
jj -R "$case_repo" git import >/dev/null 2>&1
jj -R "$case_repo" bookmark set old-local -r @- >/dev/null 2>&1
set -l old_ws "$case_home/Workspaces/github.com/acme/repo/old-local"
mkdir -p "$old_ws"
touch -d "2020-01-01 00:00:00" "$old_ws"

env GIT_COMMITTER_DATE="2025-01-01T00:00:00Z" git -C "$case_repo" commit --allow-empty -m "new remote" --date "2025-01-01T00:00:00Z" >/dev/null 2>&1
jj -R "$case_repo" git import >/dev/null 2>&1
git -C "$case_repo" update-ref refs/remotes/origin/new-remote HEAD
jj -R "$case_repo" git import >/dev/null 2>&1
jj -R "$case_repo" bookmark delete main >/dev/null 2>&1

set -l new_remote_path "$case_home/Workspaces/github.com/acme/repo/new-remote"
run_launcher "$case_home" "$case_repo" existing 0 "$new_remote_path"
test (jj --ignore-working-copy -R "$case_repo" workspace root --name new-remote) = "$new_remote_path"
or fail "launcher did not pick newer remote bookmark over older local workspace"

# --- Deduplication test ---

setup_case deduplicate_synced_bookmarks
env GIT_COMMITTER_DATE="2024-01-01T00:00:00Z" git -C "$case_repo" commit --allow-empty -m "synced commit" --date "2024-01-01T00:00:00Z" >/dev/null 2>&1
jj -R "$case_repo" git import >/dev/null 2>&1
jj -R "$case_repo" bookmark set synced-feature -r @- >/dev/null 2>&1
git -C "$case_repo" update-ref refs/remotes/origin/synced-feature HEAD
jj -R "$case_repo" git import >/dev/null 2>&1

env GIT_COMMITTER_DATE="2024-02-01T00:00:00Z" git -C "$case_repo" commit --allow-empty -m "origin commit" --date "2024-02-01T00:00:00Z" >/dev/null 2>&1
jj -R "$case_repo" git import >/dev/null 2>&1
git -C "$case_repo" update-ref refs/remotes/origin/diverged-feature HEAD
jj -R "$case_repo" git import >/dev/null 2>&1

env GIT_COMMITTER_DATE="2024-03-01T00:00:00Z" git -C "$case_repo" commit --allow-empty -m "local commit" --date "2024-03-01T00:00:00Z" >/dev/null 2>&1
jj -R "$case_repo" git import >/dev/null 2>&1
jj -R "$case_repo" bookmark set diverged-feature -r @- >/dev/null 2>&1

env GIT_COMMITTER_DATE="2024-04-01T00:00:00Z" git -C "$case_repo" commit --allow-empty -m "remote only commit" --date "2024-04-01T00:00:00Z" >/dev/null 2>&1
jj -R "$case_repo" git import >/dev/null 2>&1
git -C "$case_repo" update-ref refs/remotes/origin/remote-only HEAD
jj -R "$case_repo" git import >/dev/null 2>&1

jj -R "$case_repo" bookmark delete main >/dev/null 2>&1

set -l expected_path "$case_home/Workspaces/github.com/acme/repo/remote-only"
run_launcher "$case_home" "$case_repo" existing 0 "$expected_path"

set -l bm_content (string collect < "$launcher_bookmark_log")
string match -q "*synced-feature*" "$bm_content"
or fail "synced-feature missing from bookmark prompt"
not string match -q "*synced-feature@origin*" "$bm_content"
or fail "synced-feature@origin should have been deduplicated"
string match -q "*diverged-feature*" "$bm_content"
or fail "diverged-feature missing from bookmark prompt"
string match -q "*diverged-feature@origin*" "$bm_content"
or fail "diverged-feature@origin missing from bookmark prompt"
string match -q "*remote-only@origin*" "$bm_content"
or fail "remote-only@origin missing from bookmark prompt"

echo "start-workspace tests passed"
