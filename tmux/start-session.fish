#!/usr/bin/env fish

set -x PATH $HOME/.local/bin /usr/local/bin /usr/bin /bin $PATH

command -q fzf; or exit 0

# --- Shared fzf helpers ---

function _fail --argument-names msg
    echo "$msg" >&2
    exit 1
end

function _fzf_pick_compact --argument-names prompt
    fzf --prompt="$prompt> " --height=40% --reverse --bind='j:down,k:up'
end

function _fzf_pick_full --argument-names prompt
    fzf --prompt="$prompt> " --height=100% --reverse
end

function _fzf_pick_or_query --argument-names prompt
    fzf --prompt="$prompt> " --height=100% --reverse \
        --print-query --bind='tab:replace-query,enter:replace-query+print-query+accept'
end

function _handle_fzf_status --argument-names status_code prompt
    switch "$status_code"
        case 0
            return 0
        case 1 130
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

function _session_name_for --argument-names base suffix
    if test -n "$suffix"
        printf '%s(%s)\n' "$base" "$suffix"
    else
        printf '%s\n' "$base"
    end
end

function _select_or_create_dir --argument-names base_dir prompt
    set -l dirs
    for d in "$base_dir"/*/
        test -d "$d"; or continue
        set -a dirs (basename "$d")
    end

    set -l chosen (printf '%s\n' $dirs | _fzf_pick_or_query "$prompt")
    set -l status_code $status
    _handle_fzf_status "$status_code" "$prompt"; or return 1

    set -l dir_name (_last_non_empty_line $chosen)
    test -n "$dir_name"; or return 1

    set -l session_root "$base_dir/$dir_name"
    mkdir -p "$session_root"
    or begin
        echo "Failed to create directory: $session_root" >&2
        exit 1
    end

    printf '%s\n' "$session_root"
end

# --- Repo discovery (shared by Code, Workspace) ---

function discover_repos
    if command -q fd
        set -l repos
        for git_path in (fd --hidden --follow --glob '.git' . "$HOME/Code" 2>/dev/null)
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

function _pick_repo_rel --argument-names prompt
    set -l suggestions (discover_repos)
    set -l picked
    if test (count $suggestions) -gt 0
        set picked (printf '%s\n' $suggestions | _fzf_pick_or_query "$prompt")
    else
        set picked (printf '\n' | _fzf_pick_or_query "$prompt")
    end

    set -l status_code $status
    _handle_fzf_status "$status_code" "$prompt"; or return 1

    set -l input (_last_non_empty_line $picked)
    test -n "$input"; or return 1

    if contains -- "$input" $suggestions
        printf '%s\n' "$input"
        return 0
    end

    _resolve_clone_input "$input"
    or _fail "Unsupported repository format: $input"

    set -l repo_rel "$_clone_repo_rel"
    set -l clone_url "$_clone_url"
    set -l fallback_url "$_clone_fallback_url"
    set -l dest "$HOME/Code/$repo_rel"

    if test -e "$dest"
        if not test -d "$dest"
            _fail "Destination exists and is not a directory: $dest"
        end
        if not test -d "$dest/.git"; and not test -f "$dest/.git"; and not test -d "$dest/.jj"
            _fail "Destination exists but is not a Git/JJ repo: $dest"
        end
    else
        mkdir -p (dirname "$dest")
        or _fail "Failed to create destination parent for $dest"
        if not jj git clone "$clone_url" "$dest" >/dev/null 2>&1
            if test -n "$fallback_url"
                jj git clone "$fallback_url" "$dest" >/dev/null 2>&1
                or _fail "Failed to clone repository via SSH and HTTPS."
            else
                _fail "Failed to clone repository: $clone_url"
            end
        end
    end

    printf '%s\n' "$repo_rel"
end

function _ensure_jj_repo_ready --argument-names repo_path
    if not test -d "$repo_path/.jj"
        jj git init --colocate "$repo_path" >/dev/null 2>&1
        or _fail "Failed to initialize jj in $repo_path"
    end

    set -l colocation_status (jj -R "$repo_path" git colocation status 2>&1)
    or _fail "$colocation_status"
    if not string match -rq "currently colocated" -- "$colocation_status"
        jj -R "$repo_path" git colocation enable >/dev/null 2>&1
        or _fail "Failed to enable jj/git colocation in $repo_path"
    end

    jj -R "$repo_path" git import >/dev/null 2>&1
    or _fail "Failed to import git refs into jj for $repo_path"

    jj -R "$repo_path" git fetch --remote origin --branch main >/dev/null 2>&1
    or _fail "Failed to fetch origin/main for $repo_path"
end

# --- Agent selection (shared) ---

function select_agent
    set agent_choice (printf '%s\n' codex gemini claude \
        | _fzf_pick_compact Agent)
    set status_code $status
    _handle_fzf_status "$status_code" Agent; or return 1

    switch "$agent_choice"
        case codex
            set -g agent_cmd codex
            set -g agent_bin codex
        case gemini
            set -g agent_cmd gemini
            set -g agent_bin gemini
        case claude
            set -g agent_cmd claude --dangerously-skip-permissions
            set -g agent_bin claude
        case '*'
            echo "Unknown agent selection: $agent_choice" >&2
            return 1
    end

    command -q "$agent_bin"
    or begin
        echo "Selected agent command not found: $agent_bin" >&2
        return 1
    end
end

# --- Session launcher ---

function _launch_session
    set session_name $argv[1]
    set session_root $argv[2]

    if tmux has-session -t $session_name 2>/dev/null
        tmux switch-client -t $session_name
    else
        tmux new-session -d -s $session_name -c $session_root -n editor
        tmux send-keys -t "$session_name:editor" $agent_cmd Enter
        tmux switch-client -t $session_name
    end
end

# --- Type selection ---

set session_type (printf '%s\n' Activity Project Code Workspace \
    | _fzf_pick_compact Session)
set status_code $status
_handle_fzf_status "$status_code" Session; or exit 0

# --- Activity ---

if test "$session_type" = Activity
    set session_root (_select_or_create_dir "$HOME/Activities" Activity)
    or exit 0

    select_agent; or exit 0

    set dir_name (basename "$session_root")
    set session_name (_session_name_for "$dir_name")

    _launch_session $session_name $session_root
    exit 0
end

# --- Project ---

if test "$session_type" = Project
    set session_root (_select_or_create_dir "$HOME/Projects" Project)
    or exit 0

    select_agent; or exit 0

    set dir_name (basename "$session_root")
    set session_name (_session_name_for "$dir_name")

    _launch_session $session_name $session_root
    exit 0
end

# --- Code ---

if test "$session_type" = Code
    set repo_rel (_pick_repo_rel Code)
    or exit 0

    select_agent; or exit 0

    command -q jj
    or begin
        echo "jj is required for Code sessions: not found in PATH." >&2
        exit 1
    end

    set repo_path "$HOME/Code/$repo_rel"
    _ensure_jj_repo_ready "$repo_path"

    set repo_parts (string split '/' -- $repo_rel)
    set session_name (_session_name_for "$repo_parts[-1]")

    _launch_session $session_name "$repo_path"
    exit 0
end

# --- Workspace ---

if test "$session_type" = Workspace
    command -q jj; or exit 0

    set repo_rel (_pick_repo_rel Workspace)
    or exit 0

    set repo_path "$HOME/Code/$repo_rel"
    set repo_parts (string split '/' -- $repo_rel)
    set repo_name $repo_parts[-1]
    _ensure_jj_repo_ready "$repo_path"

    set local_bookmarks (jj -R "$repo_path" bookmark list -T 'self.name() ++ "\n"' | sed '/^$/d' | sort -u)
    set remote_bookmarks (jj -R "$repo_path" bookmark list --all-remotes -T 'if(self.remote(), self.name() ++ "@" ++ self.remote(), "") ++ "\n"' \
        | sed '/^$/d' \
        | sort -u)
    set suggestion_bookmarks (printf '%s\n' $local_bookmarks $remote_bookmarks | sed '/^$/d' | sort -u)

    set bookmark_input (printf '%s\n' $suggestion_bookmarks | _fzf_pick_or_query Bookmark)
    set status_code $status
    _handle_fzf_status "$status_code" Bookmark; or exit 0

    set selected_bookmark (_last_non_empty_line $bookmark_input)
    test -n "$selected_bookmark"; or exit 0

    set bookmark "$selected_bookmark"
    set selected_remote_ref ""
    set selected_remote_parts (string match -r --groups-only '^(.+)@origin$' -- "$selected_bookmark")
    if test (count $selected_remote_parts) -eq 1
        set bookmark "$selected_remote_parts[1]"
        set selected_remote_ref "$selected_bookmark"
    end

    if not string match -rq '^[A-Za-z0-9._/-]+$' -- "$bookmark"
        echo "Invalid bookmark name: $selected_bookmark" >&2
        exit 1
    end

    set workspace_path "$HOME/Workspaces/$repo_rel/$bookmark"
    set workspace_parent (dirname "$workspace_path")
    set bookmark_exists 0
    if contains -- "$bookmark" $local_bookmarks
        set bookmark_exists 1
    end

    if test -d "$workspace_path"
        jj -R "$workspace_path" root >/dev/null 2>&1
        or begin
            echo "Path exists but is not a jj workspace: $workspace_path" >&2
            echo "Move/remove that directory and retry." >&2
            exit 1
        end
    else
        mkdir -p "$workspace_parent"

        jj -R "$repo_path" git fetch --remote origin >/dev/null 2>&1
        or begin
            echo "Failed to fetch origin for $repo_path" >&2
            exit 1
        end

        jj -R "$repo_path" log -r 'main@origin' --no-graph --limit 1 >/dev/null 2>&1
        or begin
            echo "Missing main@origin in $repo_path; cannot create workspace base." >&2
            exit 1
        end

        if test -n "$selected_remote_ref"
            jj -R "$repo_path" log -r "$selected_remote_ref" --no-graph --limit 1 >/dev/null 2>&1
            or begin
                echo "Missing remote bookmark $selected_remote_ref in $repo_path." >&2
                exit 1
            end
            set base_rev "$selected_remote_ref"
        else
            set origin_bookmark_exists 0
            jj -R "$repo_path" log -r "$bookmark@origin" --no-graph --limit 1 >/dev/null 2>&1
            and set origin_bookmark_exists 1

            if test $bookmark_exists -eq 1
                set base_rev "$bookmark"
            else if test $origin_bookmark_exists -eq 1
                set base_rev "$bookmark@origin"
            else
                set base_rev 'main@origin'
            end
        end

        jj -R "$repo_path" workspace forget "$bookmark" >/dev/null 2>&1 || true

        jj -R "$repo_path" workspace add --name "$bookmark" -r "$base_rev" "$workspace_path" >/dev/null 2>&1
        or begin
            echo "Failed to create workspace at $workspace_path" >&2
            exit 1
        end

        if test $bookmark_exists -eq 0
            jj -R "$workspace_path" bookmark set "$bookmark" -r @ >/dev/null 2>&1
            or begin
                echo "Failed to create bookmark $bookmark in $workspace_path" >&2
                exit 1
            end
        end
    end

    select_agent; or exit 0

    set session_name (_session_name_for "$repo_name" "$bookmark")

    _launch_session $session_name "$HOME/Workspaces/$repo_rel/$bookmark"
    exit 0
end
