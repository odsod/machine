#!/usr/bin/env fish

set -x PATH $HOME/.local/bin /usr/local/bin /usr/bin /bin $PATH

command -q fzf; or exit 0

# --- Shared fzf helpers ---

function _fail --argument-names msg
    echo "$msg" >&2
    exit 1
end

function _fzf_pick_or_query --argument-names prompt
    fzf --prompt="$prompt> " --height=100% --reverse \
        --print-query --bind='tab:replace-query,enter:replace-query+print-query+accept'
end

function _handle_pick_or_query_status --argument-names status_code prompt raw_value
    switch "$status_code"
        case 0
            return 0
        case 1
            set -l value (_last_non_empty_line $raw_value)
            test -n "$value"; and return 0
            return 1
        case 130
            return 1
        case '*'
            echo "$prompt picker failed (fzf exit $status_code)" >&2
            exit 1
    end
end

function _last_non_empty_line
    set -l last
    for line in $argv
        set line (string trim -- "$line")
        if test -n "$line"
            set last "$line"
        end
    end
    printf '%s\n' "$last"
end

# --- Repo discovery ---

function discover_repos
    if command -q fd
        set -l repos
        for git_path in (fd --hidden --follow --glob '.git' --search-path "$HOME/Code" 2>/dev/null)
            set -l repo_dir (dirname "$git_path")
            set -l rel (string replace -r "^$HOME/Code/" "" -- "$repo_dir")
            if string match -rq '^[^/]+/[^/]+/[^/]+$' -- "$rel"
                set -a repos "$rel"
            end
        end
        printf '%s\n' $repos | sort -u
    else
        set repos
        for host_dir in $HOME/Code/*
            test -d $host_dir; or continue
            for org_dir in $host_dir/*
                test -d $org_dir; or continue
                for repo_dir in $org_dir/*
                    test -d $repo_dir; or continue
                    if test -d $repo_dir/.git; or test -f $repo_dir/.git
                        set rel (string replace -r "^$HOME/Code/" "" -- $repo_dir)
                        set -a repos $rel
                    end
                end
            end
        end
        printf '%s\n' $repos | sort -u
    end
end

# --- Clone logic ---

function _resolve_clone_input --argument-names input
    set -g _clone_repo_rel ""
    set -g _clone_url ""
    set -g _clone_fallback_url ""

    # GitHub shorthand: org/repo
    set -l shorthand (string match -r --groups-only '^([^/]+)/([^/]+)$' -- "$input")
    if test (count $shorthand) -eq 2
        set -l org "$shorthand[1]"
        set -l repo "$shorthand[2]"
        set -g _clone_repo_rel "github.com/$org/$repo"
        set -g _clone_url "git@github.com:$org/$repo.git"
        set -g _clone_fallback_url "https://github.com/$org/$repo.git"
        return 0
    end

    # SCP-style URL: git@host:path/to/repo(.git)
    set -l scp_parts (string match -r --groups-only '^[^@]+@([^:]+):(.+)$' -- "$input")
    if test (count $scp_parts) -eq 2
        set -l host "$scp_parts[1]"
        set -l path "$scp_parts[2]"
        set path (string replace -r '^/+|/+$' '' -- "$path")
        set path (string replace -r '\.git$' '' -- "$path")
        test -n "$path"; or return 1
        set -g _clone_repo_rel "$host/$path"
        set -g _clone_url "$input"
        return 0
    end

    # URL with scheme: https://host/path/to/repo(.git), ssh://host/path
    set -l url_parts (string match -r --groups-only '^[a-zA-Z][a-zA-Z0-9+.-]*://([^/]+)/(.+)$' -- "$input")
    if test (count $url_parts) -eq 2
        set -l host "$url_parts[1]"
        set host (string replace -r '^.*@' '' -- "$host")
        set -l path "$url_parts[2]"
        set path (string replace -r '^/+|/+$' '' -- "$path")
        set path (string replace -r '\.git$' '' -- "$path")
        test -n "$path"; or return 1
        set -g _clone_repo_rel "$host/$path"
        set -g _clone_url "$input"
        return 0
    end

    return 1
end

# --- Main ---

set -l already_cloned (discover_repos)
set -l suggestions
if command -q gh
    printf "  Fetching GitHub repos..."
    set -l tmpdir (mktemp -d)
    gh api user --jq '.login' > "$tmpdir/_user" 2>/dev/null &
    gh api user/orgs --jq '.[].login' > "$tmpdir/_orgs" 2>/dev/null &
    wait
    set -l all_owners (cat "$tmpdir/_user") (cat "$tmpdir/_orgs")
    for owner in $all_owners
        gh repo list "$owner" --limit 200 --json nameWithOwner \
            --jq '.[].nameWithOwner' > "$tmpdir/$owner" 2>/dev/null &
    end
    wait
    printf "\r\033[K"
    for owner in $all_owners
        for repo in (cat "$tmpdir/$owner" 2>/dev/null)
            if not contains -- "github.com/$repo" $already_cloned
                set -a suggestions "$repo"
            end
        end
    end
    rm -rf "$tmpdir"
end

set -l picked
if test (count $suggestions) -gt 0
    set picked (printf '%s\n' $suggestions | _fzf_pick_or_query Clone)
else
    set picked (printf '\n' | _fzf_pick_or_query Clone)
end

set -l status_code $status
_handle_pick_or_query_status "$status_code" Clone "$picked"; or exit 0

set -l value (_last_non_empty_line $picked)
test -n "$value"; or exit 0

_resolve_clone_input "$value"
or _fail "Unsupported repository format: $value"

set -l dest "$HOME/Code/$_clone_repo_rel"

if test -e "$dest"
    echo "Already exists: $dest"
    exit 0
end

mkdir -p (dirname "$dest")
or _fail "Failed to create destination parent for $dest"

if not jj git clone "$_clone_url" "$dest" 2>&1
    if test -n "$_clone_fallback_url"
        jj git clone "$_clone_fallback_url" "$dest" 2>&1
        or _fail "Failed to clone repository via SSH and HTTPS."
    else
        _fail "Failed to clone repository: $_clone_url"
    end
end

read -P "Cloned to $dest — press Enter to close" _
