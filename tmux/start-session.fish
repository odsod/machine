#!/usr/bin/env fish

set -x PATH $HOME/.local/bin /usr/local/bin /usr/bin /bin $PATH

command -q fzf; or exit 0

# --- Shared fzf helpers ---

function _fail --argument-names msg
    echo "$msg" >&2
    _trace "FAIL: $msg"
    exit 1
end

function _trace --argument-names msg
    if test -n "$START_SESSION_DEBUG"
        mkdir -p "$HOME/.cache"
        printf '%s %s\n' (date '+%Y-%m-%d %H:%M:%S') "$msg" >> "$HOME/.cache/start-session.log"
    end
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

function _status_show --argument-names msg
    printf '\r\033[2K%s' "$msg"
end

function _status_clear
    printf '\r\033[2K'
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
    _handle_pick_or_query_status "$status_code" "$prompt" "$chosen"; or return 1

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

function _pick_repo_rel --argument-names prompt
    set -l suggestions (discover_repos)
    if test (count $suggestions) -eq 0
        echo "No repos found in ~/Code." >&2
        return 1
    end
    set -l picked (printf '%s\n' $suggestions | _fzf_pick_full "$prompt")
    set -l status_code $status
    _handle_fzf_status "$status_code" "$prompt"; or return 1
    test -n "$picked"; or return 1
    printf '%s\n' "$picked"
end

function _jj_repo --argument-names repo_path
    jj --ignore-working-copy -R "$repo_path" $argv[2..-1]
end

function _ensure_jj_repo_ready --argument-names repo_path
    if not test -d "$repo_path/.jj"
        jj git init --colocate "$repo_path" >/dev/null 2>&1
        or _fail "Failed to initialize jj in $repo_path"
    end

    set -l colocation_status (_jj_repo "$repo_path" git colocation status 2>&1)
    or _fail "$colocation_status"
    if not string match -rq "currently colocated" -- "$colocation_status"
        _jj_repo "$repo_path" git colocation enable >/dev/null 2>&1
        or _fail "Failed to enable jj/git colocation in $repo_path"
    end

    _jj_repo "$repo_path" git import >/dev/null 2>&1
    or _fail "Failed to import git refs into jj for $repo_path"

    _jj_repo "$repo_path" git fetch --remote origin --branch main >/dev/null 2>&1
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

set session_type (printf '%s\n' Workspace Code Activity Project \
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

    _trace "workspace: begin"
    set repo_rel (_pick_repo_rel Workspace)
    or exit 0

    set repo_path "$HOME/Code/$repo_rel"
    set repo_parts (string split '/' -- $repo_rel)
    set repo_name $repo_parts[-1]
    _ensure_jj_repo_ready "$repo_path"

    set local_bookmarks (_jj_repo "$repo_path" bookmark list -T 'self.name() ++ "\n"' 2>/dev/null | sed '/^$/d' | sort -u)
    set remote_bookmarks (_jj_repo "$repo_path" bookmark list --all-remotes -T 'if(self.remote(), self.name() ++ "@" ++ self.remote(), "") ++ "\n"' 2>/dev/null \
        | sed '/^$/d' \
        | sort -u)
    set suggestion_bookmarks (printf '%s\n' $local_bookmarks $remote_bookmarks | sed '/^$/d' | sort -u)

    set bookmark_input ""
    if test (count $suggestion_bookmarks) -gt 0
        set bookmark_input (printf '%s\n' $suggestion_bookmarks | _fzf_pick_or_query Bookmark)
    else
        set bookmark_input (printf '\n' | _fzf_pick_or_query Bookmark)
    end
    set status_code $status
    _handle_pick_or_query_status "$status_code" Bookmark "$bookmark_input"; or exit 0

    set selected_bookmark (_last_non_empty_line $bookmark_input)
    test -n "$selected_bookmark"; or exit 0
    _trace "workspace: repo=$repo_rel bookmark_input=$selected_bookmark"

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

    set desired_workspace_path "$HOME/Workspaces/$repo_rel/$bookmark"
    set workspace_path "$desired_workspace_path"
    set existing_workspace_path (_jj_repo "$repo_path" workspace root --name "$bookmark" 2>/dev/null)
    if test $status -eq 0
        if test -n "$existing_workspace_path"
            if test -d "$existing_workspace_path"
                set workspace_path "$existing_workspace_path"
            else
                _jj_repo "$repo_path" workspace forget "$bookmark" >/dev/null 2>&1 || true
            end
        end
    end

    set workspace_parent (dirname "$workspace_path")
    set bookmark_exists 0
    if contains -- "$bookmark" $local_bookmarks
        set bookmark_exists 1
    end
    _status_show "Setting up worktree..."

    if test -d "$workspace_path"
        _trace "workspace: existing path $workspace_path"
        jj --ignore-working-copy -R "$workspace_path" root >/dev/null 2>&1
        or begin
            _status_clear
            echo "Path exists but is not a jj workspace: $workspace_path" >&2
            _trace "workspace: existing path is not jj workspace"
            echo "Move/remove that directory and retry." >&2
            exit 1
        end
    else
        mkdir -p "$workspace_parent"
        or begin
            _status_clear
            echo "Failed to create workspace parent: $workspace_parent" >&2
            _trace "workspace: mkdir failed $workspace_parent"
            exit 1
        end

        # Refresh remote refs if possible, but do not require network/auth for local workspace creation.
        _jj_repo "$repo_path" git fetch --remote origin >/dev/null 2>&1 || true

        if test -n "$selected_remote_ref"
            _jj_repo "$repo_path" log -r "$selected_remote_ref" --no-graph --limit 1 >/dev/null 2>&1
            or begin
                _status_clear
                echo "Missing remote bookmark $selected_remote_ref in $repo_path." >&2
                _trace "workspace: missing remote ref $selected_remote_ref"
                exit 1
            end
            set base_rev "$selected_remote_ref"
        else
            set origin_bookmark_exists 0
            _jj_repo "$repo_path" log -r "$bookmark@origin" --no-graph --limit 1 >/dev/null 2>&1
            and set origin_bookmark_exists 1

            if test $origin_bookmark_exists -eq 1
                set base_rev "$bookmark@origin"
            else if test $bookmark_exists -eq 1
                set base_rev "$bookmark"
            else if _jj_repo "$repo_path" log -r 'main@origin' --no-graph --limit 1 >/dev/null 2>&1
                set base_rev 'main@origin'
            else if _jj_repo "$repo_path" log -r 'main' --no-graph --limit 1 >/dev/null 2>&1
                set base_rev 'main'
            else
                set base_rev '@'
            end
        end
        _trace "workspace: creating with base_rev=$base_rev path=$workspace_path"

        _jj_repo "$repo_path" workspace forget "$bookmark" >/dev/null 2>&1 || true

        _jj_repo "$repo_path" workspace add --name "$bookmark" -r "$base_rev" "$workspace_path" >/dev/null 2>&1
        or begin
            _status_clear
            echo "Failed to create workspace at $workspace_path" >&2
            _trace "workspace: workspace add failed"
            exit 1
        end

        if test $bookmark_exists -eq 0
            jj --ignore-working-copy -R "$workspace_path" bookmark set "$bookmark" -r @ >/dev/null 2>&1
            or begin
                _status_clear
                echo "Failed to create bookmark $bookmark in $workspace_path" >&2
                _trace "workspace: bookmark set failed for $bookmark"
                exit 1
            end
        end
    end

    _status_clear
    _trace "workspace: selecting agent"
    select_agent; or exit 0
    _trace "workspace: launching session"

    set session_name (_session_name_for "$repo_name" "$bookmark")

    _launch_session $session_name "$workspace_path"
    exit 0
end
