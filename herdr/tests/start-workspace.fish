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
        'switch "$count"' \
        '    case 1' \
        '        echo Workspace' \
        '    case 2' \
        '        head -n1' \
        '    case 3' \
        '        if test "$FZF_BOOKMARK_MODE" = typed' \
        '            cat >/dev/null' \
        '            echo typed' \
        '        else' \
        '            head -n1' \
        '        end' \
        '    case 4' \
        '        echo codex' \
        '    case "*"' \
        '        exit 2' \
        'end' > "$stub_bin/fzf"

    printf '%s\n' \
        "#!$real_fish --no-config" \
        'printf "%s\n" (string join " " -- $argv) >> "$HERDR_LOG"' \
        'set -l command_line (string join " " -- $argv)' \
        'switch "$command_line"' \
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
        'end' > "$stub_bin/herdr"

    printf '%s\n' \
        "#!$real_fish --no-config" \
        'command "$REAL_JJ" $argv' > "$stub_bin/jj"

    printf '%s\n' "#!$real_fish --no-config" 'exit 0' > "$stub_bin/codex"
    printf '%s\n' "#!$real_fish --no-config" 'exit 1' > "$stub_bin/timeout"
    chmod +x "$stub_bin/fzf" "$stub_bin/herdr" "$stub_bin/jj" \
        "$stub_bin/codex" "$stub_bin/timeout"
end

function setup_case --argument-names name
    set -g case_home "$test_root/$name/home"
    set -g case_repo "$case_home/Code/github.com/acme/repo"
    mkdir -p "$case_repo"
    write_stubs "$case_home"
    jj git init --colocate "$case_repo" >/dev/null
    or fail "could not initialize launcher test repo"
end

function run_launcher --argument-names home repo mode existing expected_cwd
    set -l count_file "$home/fzf-count"
    set -l herdr_log "$home/herdr.log"
    set -l system_path (string join : $PATH)
    rm -f "$count_file" "$herdr_log"

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
        HERDR_PANE_ID= \
        "$real_fish" --no-config "$start_script" >/dev/null
    set -l launcher_status $status
    cd "$original_dir"
    test $launcher_status -eq 0; or fail "launcher failed in $mode mode"

    set -g launcher_log "$herdr_log"
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
string match -q '*workspace create*--label repo/feature*' (string collect < "$existing_log")
or fail "launcher did not create the existing bookmark workspace"
string match -q '*agent start codex-wcase --kind codex --pane wCase:p1*' \
    (string collect < "$existing_log")
or fail "launcher did not use returned Herdr IDs for agent startup"

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

echo "start-workspace tests passed"
