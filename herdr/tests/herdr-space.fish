#!/usr/bin/env fish

set -g test_dir (path resolve (dirname (status filename)))
set -g helper (path resolve "$test_dir/../herdr-space")
set -g test_root (mktemp -d)
set -g real_fish (status fish-path)

function cleanup --on-event fish_exit
    rm -rf "$test_root"
end

function fail --argument-names message
    echo "FAIL: $message" >&2
    exit 1
end

# Real tool folders: under the test HOME, mise finds no global tools.
set -gx PATH (mise bin-paths 2>/dev/null) (string match -v -- '*/mise/shims' $PATH)
set -gx HOME "$test_root/home"
set -g stub_bin "$test_root/bin"
mkdir -p "$HOME" "$stub_bin" "$test_root/trash"
set -gx PATH "$stub_bin" $PATH
printf '%s\n' "#!$real_fish --no-config" 'mv -- $argv[2] '"$test_root/trash/" >"$stub_bin/gio"
chmod +x "$stub_bin/gio"
set -gx JJ_CONFIG "$test_root/jj.toml"
printf '%s\n' '[user]' 'name = "Test"' 'email = "test@example.com"' >"$JJ_CONFIG"

set -g repo_rel example.com/org/repo
set -g repo "$HOME/Code/$repo_rel"
mkdir -p (path dirname "$repo")
jj git init --colocate "$repo" >/dev/null 2>&1; or fail "could not create repo"
echo a >"$repo/a"
jj -R "$repo" commit -m base >/dev/null 2>&1
jj -R "$repo" bookmark set main -r @- >/dev/null 2>&1; or fail "could not set main"

function run_helper
    $real_fish --no-config "$helper" $argv
end

# repos
run_helper repos | jq -e --arg r "$repo_rel" 'map(.repo) == [$r]' >/dev/null
or fail "repos does not list $repo_rel"

# prepare workspace with a new bookmark
set -l out (run_helper prepare workspace "$repo_rel" feat-x); or fail "prepare workspace failed"
set -l ws "$HOME/Workspaces/$repo_rel/feat-x"
printf '%s' "$out" | jq -e --arg p "$ws" '.path == $p and .label == "repo/feat-x"' >/dev/null
or fail "prepare workspace printed $out"
test -d "$ws/.jj"; or fail "workspace folder missing"
run_helper bookmarks "$repo_rel" | jq -e 'map(.name) | index("feat-x")' >/dev/null
or fail "bookmarks does not list feat-x"

# prepare again reuses the workspace
set out (run_helper prepare workspace "$repo_rel" feat-x); or fail "second prepare failed"
printf '%s' "$out" | jq -e --arg p "$ws" '.path == $p' >/dev/null; or fail "second prepare printed $out"

# workspaces lists it, with its changes
echo b >"$ws/b"
jj -R "$ws" status >/dev/null 2>&1
run_helper workspaces | jq -e --arg p "$ws" '.[0].path == $p and .[0].name == "feat-x" and (.[0].changes | length) == 1' >/dev/null
or fail "workspaces does not list feat-x with one change"

# remove refuses the default checkout and paths outside ~/Workspaces
run_helper remove "$repo" >/dev/null 2>&1; and fail "remove accepted the default checkout"
test -d "$repo/.jj"; or fail "default checkout was touched"

# remove forgets the workspace, trashes the folder, keeps the changes
set out (run_helper remove "$ws"); or fail "remove failed"
test -e "$ws"; and fail "workspace folder still exists"
test -d "$test_root/trash/feat-x"; or fail "workspace folder not in trash"
jj -R "$repo" workspace list -T 'name ++ "\n"' | string match -q feat-x; and fail "workspace not forgotten"
set -l kept (printf '%s' "$out" | jq -r .kept)
test -n "$kept"; or fail "remove kept no commit: $out"
jj -R "$repo" log -r "$kept" --no-graph -T 'empty' | string match -q false; or fail "kept commit $kept is not visible"

# folders: a new project gets a date prefix, an unknown vault fails
set out (run_helper prepare project demo); or fail "prepare project failed"
set -l project (date '+%Y-%m-%d')-demo
printf '%s' "$out" | jq -e --arg l "$project" '.label == $l' >/dev/null; or fail "project printed $out"
test -d "$HOME/Projects/$project"; or fail "project folder missing"
run_helper prepare vault nope >/dev/null 2>&1; and fail "prepare made a vault"
run_helper dirs project | jq -e --arg n "$project" '.[0].name == $n' >/dev/null; or fail "dirs does not list $project"

echo "ok"
