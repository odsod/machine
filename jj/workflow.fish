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

function post_publish_new_working_commit
    jj new @ >/dev/null
    or fail "Failed to create follow-up working commit after publish."
    echo "Started new working commit on top of published change."
end

function ensure_head_at_current --argument-names head
    set -l head_at_current (jj log -r "bookmarks(\"$head\") & @" --no-graph | string collect)
    if test -n "$head_at_current"
        return 0
    end

    set -l current_in_head_lineage (jj log -r "@ & descendants(bookmarks(\"$head\"))" --no-graph | string collect)
    if test -z "$current_in_head_lineage"
        fail "Current commit is not in lineage of $head. Run: jj new $head or pass correct head."
    end

    jj bookmark set "$head" -r @
    or fail "Failed to move $head to current commit."
end

function sub_sync
    fetch_origin
    echo "Synced refs from origin."
end

function sub_clean
    fetch_origin

    set -l to_delete
    for b in (jj bookmark list | awk '/^odsod\/push-/{gsub(":", "", $1); print $1}')
        set -l merged_hit (jj log -r "bookmarks(\"$b\") & ::main@origin" --no-graph | string collect)
        if test -n "$merged_hit"
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
    post_publish_new_working_commit
end

function sub_pr_update
    ensure_pr_preflight

    set -l repo (github_repo_from_origin)
    test -n "$repo"; or fail "Could not infer GitHub repo from origin remote."

    set -l head
    if test (count $argv) -gt 1
        fail "Usage: jj pr-update [head-bookmark]"
    else if test (count $argv) -eq 1
        set head "$argv[1]"
    else
        set -l candidates
        for b in (jj bookmark list -T 'self.name() ++ "\n"' | sed '/^$/d' | sort -u)
            if test "$b" = "main"
                continue
            end
            set -l lineage_hit (jj log -r "bookmarks(\"$b\") & ancestors(@)" --no-graph | string collect)
            if test -n "$lineage_hit"
                if not contains -- "$b" $candidates
                    set -a candidates "$b"
                end
            end
        end

        set -l matched_heads
        for c in $candidates
            set -l pr_url (gh pr list --repo "$repo" --state open --head "$c" --json url --jq '.[0].url')
            if test -n "$pr_url"; and test "$pr_url" != "null"
                set -a matched_heads "$c"
            end
        end

        if test (count $matched_heads) -eq 1
            set head "$matched_heads[1]"
        else if test (count $matched_heads) -gt 1
            echo "Multiple open PR heads match current lineage:"
            for h in $matched_heads
                echo "  $h"
            end
            fail "Use: jj pr-update <head-bookmark>"
        else
            set head (current_head_bookmark)
        end
    end

    test -n "$head"; or fail "Could not determine PR head bookmark."

    set -l pr_number (gh pr list --repo "$repo" --state open --head "$head" --json number --jq '.[0].number')
    if test -z "$pr_number"; or test "$pr_number" = "null"
        fail "No existing PR found for $head. Use jj pr to create one."
    end

    jj bookmark track "$head" --remote=origin >/dev/null 2>&1 || true
    ensure_head_at_current "$head"
    jj git push --remote origin --bookmark "$head"
    or fail "Failed to push bookmark $head."

    set -l pr_url (gh pr list --repo "$repo" --state open --head "$head" --json url --jq '.[0].url')
    test -n "$pr_url"; or fail "Could not resolve PR URL for $head."
    xdg-open "$pr_url" >/dev/null 2>&1 || true
    echo "$pr_url"
    post_publish_new_working_commit
end

function usage
    echo "Usage: jj-workflow <subcommand>"
    echo "Subcommands: sync clean start pr-check pr pr-update"
end

if not command -q jj
    fail "jj is required but not found in PATH."
end

if test (count $argv) -lt 1
    usage
    exit 1
end

set -l subcmd "$argv[1]"
set -l subargs $argv[2..-1]

switch "$subcmd"
    case sync
        test (count $subargs) -eq 0; or fail "Usage: jj sync"
        sub_sync
    case clean
        test (count $subargs) -eq 0; or fail "Usage: jj clean"
        sub_clean
    case start
        test (count $subargs) -eq 0; or fail "Usage: jj start"
        sub_start
    case pr-check
        test (count $subargs) -eq 0; or fail "Usage: jj pr-check"
        sub_pr_check
    case pr
        test (count $subargs) -eq 0; or fail "Usage: jj pr"
        sub_pr
    case pr-update
        sub_pr_update $subargs
    case '*'
        usage
        exit 1
end
