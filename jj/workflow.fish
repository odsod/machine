#!/usr/bin/env fish

function fail --argument-names msg
    echo "$msg" >&2
    exit 1
end

function fetch_origin
    jj git fetch --remote origin >/dev/null 2>&1
    or fail "Failed to fetch from origin."
end

function ensure_pr_preflight
    fetch_origin

    set -l divergent (jj log -r 'mutable() & divergent()' --no-graph)
    if test -n "$divergent"
        echo "FAIL: mutable divergent change IDs detected."
        echo "$divergent"
        exit 1
    end

    set -l rebased (jj log -r '@ & descendants(main@origin)' --no-graph)
    if test -z "$rebased"
        echo "FAIL: current commit is not rebased onto latest main@origin."
        echo "Run: jj rebase -d main@origin"
        exit 1
    end
end

function github_repo_from_origin
    set -l remote_url (jj git remote list | awk '$1=="origin"{print $2; exit}')
    test -n "$remote_url"; or return 1

    set -l repo (echo "$remote_url" | sed -E 's#^git@github.com:##; s#^https://github.com/##; s#\.git$##')
    if string match -rq '^[^/]+/[^/]+$' -- "$repo"
        echo "$repo"
        return 0
    end
    return 1
end

function current_head_bookmark
    set -l ws (jj workspace list -T 'if(self.target().current_working_copy(), self.name(), "") ++ "\n"' | sed '/^$/d' | head -n1)
    if test -n "$ws"; and test "$ws" != "default"
        set -l at_ws (jj log -r "bookmarks(\"$ws\") & @" --no-graph)
        if test -n "$at_ws"
            echo "$ws"
            return 0
        end
    end

    echo "odsod/push-"(jj log --no-graph -r @ -T 'change_id.short()')
end

function sub_sync
    fetch_origin
    echo "Synced refs from origin."
end

function sub_clean
    fetch_origin

    set -l to_delete
    for b in (jj bookmark list | awk '/^odsod\/push-/{gsub(":", "", $1); print $1}')
        if test -n (jj log -r "bookmarks(\"$b\") & ::main@origin" --no-graph)
            set -a to_delete "$b"
        end
    end

    if test (count $to_delete) -eq 0
        echo "No merged odsod/push-* bookmarks to prune."
        return 0
    end

    echo "Pruning bookmarks:"
    for b in $to_delete
        echo "  $b"
    end

    jj bookmark delete $to_delete
    or fail "Failed deleting local bookmarks."
    jj git push --remote origin --deleted
    or fail "Failed deleting remote bookmarks."
    echo "Done."
end

function sub_start
    fetch_origin
    jj new main@origin >/dev/null
    or fail "Failed to create new commit from main@origin."
    echo "Now working on a new commit on top of latest main@origin."
end

function sub_pr_check
    ensure_pr_preflight
    echo "OK: pr preflight checks passed."
end

function sub_pr
    ensure_pr_preflight

    set -l repo (github_repo_from_origin)
    test -n "$repo"; or fail "Could not infer GitHub repo from origin remote."

    set -l head (current_head_bookmark)
    test -n "$head"; or fail "Could not determine PR head bookmark."

    if string match -rq '^odsod/push-' -- "$head"
        jj git push -c @
        or fail "Failed to push current change."
    else
        jj bookmark track "$head" --remote=origin >/dev/null 2>&1 || true
        jj git push --remote origin --bookmark "$head"
        or fail "Failed to push bookmark $head."
    end

    set -l pr_url (gh pr create --repo "$repo" --head "$head" --fill)
    or fail "Failed to create PR for $head."
    xdg-open "$pr_url" >/dev/null 2>&1 || true
    echo "$pr_url"
end

function sub_pr_update
    ensure_pr_preflight

    set -l repo (github_repo_from_origin)
    test -n "$repo"; or fail "Could not infer GitHub repo from origin remote."

    set -l head (current_head_bookmark)
    test -n "$head"; or fail "Could not determine PR head bookmark."

    set -l pr_number (gh pr list --repo "$repo" --state open --head "$head" --json number --jq '.[0].number')
    if test -z "$pr_number"; or test "$pr_number" = "null"
        fail "No existing PR found for $head. Use jj pr to create one."
    end

    jj bookmark track "$head" --remote=origin >/dev/null 2>&1 || true
    jj git push --remote origin --bookmark "$head"
    or fail "Failed to push bookmark $head."

    set -l pr_url (gh pr list --repo "$repo" --state open --head "$head" --json url --jq '.[0].url')
    test -n "$pr_url"; or fail "Could not resolve PR URL for $head."
    xdg-open "$pr_url" >/dev/null 2>&1 || true
    echo "$pr_url"
end

function usage
    echo "Usage: jj-workflow <subcommand>"
    echo "Subcommands: sync clean start pr-check pr pr-update"
end

if not command -q jj
    fail "jj is required but not found in PATH."
end

if test (count $argv) -ne 1
    usage
    exit 1
end

switch "$argv[1]"
    case sync
        sub_sync
    case clean
        sub_clean
    case start
        sub_start
    case pr-check
        sub_pr_check
    case pr
        sub_pr
    case pr-update
        sub_pr_update
    case '*'
        usage
        exit 1
end
