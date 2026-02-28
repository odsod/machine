#!/usr/bin/env fish

set -x PATH $HOME/.local/bin /usr/local/bin /usr/bin /bin $PATH

command -q fzf; or exit 0
command -q smug; or exit 0

# --- Type selection ---

set session_type (printf '%s\n' Activity Project Code Workspace Worktree \
    | fzf --prompt='Session> ' --height=40% --reverse --bind='j:down,k:up')
or exit 0

# --- Repo discovery (shared by Code, Workspace, Worktree) ---

function discover_repos
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

# --- Agent selection (shared) ---

function select_agent
    set agent_choice (printf '%s\n' codex gemini claude \
        | fzf --prompt='Agent> ' --height=40% --reverse --bind='j:down,k:up')
    or return 1

    switch "$agent_choice"
        case codex
            set -g agent_cmd codex
            set -g agent_bin codex
        case gemini
            set -g agent_cmd gemini
            set -g agent_bin gemini
        case claude
            set -g agent_cmd "claude --dangerously-skip-permissions"
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

# --- Activity ---

if test "$session_type" = Activity
    set dirs
    for d in $HOME/Activities/*/
        test -d $d; or continue
        set -a dirs (basename $d)
    end

    set chosen (printf '%s\n' $dirs \
        | fzf --prompt='Activity> ' --height=100% --reverse \
              --bind='tab:replace-query,enter:print-query+accept')
    or exit 0

    set dir_name (string trim -- "$chosen")
    test -n "$dir_name"; or exit 0

    set session_root "$HOME/Activities/$dir_name"
    mkdir -p "$session_root"

    select_agent; or exit 0

    set session_name "$dir_name"

    if tmux has-session -t "$session_name" 2>/dev/null
        tmux switch-client -t "$session_name"
    else
        smug start activity -a \
            SESSION_NAME=$session_name \
            SESSION_ROOT=$session_root \
            AGENT_CMD=$agent_cmd
    end
    exit 0
end

# --- Project ---

if test "$session_type" = Project
    set dirs
    for d in $HOME/Projects/*/
        test -d $d; or continue
        set -a dirs (basename $d)
    end

    set chosen (printf '%s\n' $dirs \
        | fzf --prompt='Project> ' --height=100% --reverse \
              --bind='tab:replace-query,enter:print-query+accept')
    or exit 0

    set dir_name (string trim -- "$chosen")
    test -n "$dir_name"; or exit 0

    set session_root "$HOME/Projects/$dir_name"
    mkdir -p "$session_root"

    select_agent; or exit 0

    set session_name "$dir_name"

    if tmux has-session -t "$session_name" 2>/dev/null
        tmux switch-client -t "$session_name"
    else
        smug start project -a \
            SESSION_NAME=$session_name \
            SESSION_ROOT=$session_root \
            AGENT_CMD=$agent_cmd
    end
    exit 0
end

# --- Code ---

if test "$session_type" = Code
    set repos (discover_repos)
    test (count $repos) -gt 0; or exit 0

    set repo_rel (printf '%s\n' $repos | fzf --prompt='Code> ' --height=100% --reverse)
    or exit 0

    select_agent; or exit 0

    set repo_parts (string split '/' -- $repo_rel)
    set session_name "$repo_parts[-1]"

    if tmux has-session -t "$session_name" 2>/dev/null
        tmux switch-client -t "$session_name"
    else
        smug start code -a \
            REPO_REL=$repo_rel \
            SESSION_NAME=$session_name \
            AGENT_CMD=$agent_cmd
    end
    exit 0
end

# --- Workspace ---

if test "$session_type" = Workspace
    command -q jj; or exit 0

    set repos (discover_repos)
    test (count $repos) -gt 0; or exit 0

    set repo_rel (printf '%s\n' $repos | fzf --prompt='Workspace> ' --height=100% --reverse)
    or exit 0

    set repo_path "$HOME/Code/$repo_rel"
    set repo_parts (string split '/' -- $repo_rel)
    set repo_name $repo_parts[-1]

    if not test -d "$repo_path/.jj"
        jj git init --colocate "$repo_path"
        or begin
            echo "Failed to initialize jj in $repo_path" >&2
            exit 1
        end
    end

    set colocation_status (jj -R "$repo_path" git colocation status 2>&1)
    or begin
        echo "$colocation_status" >&2
        exit 1
    end
    if not string match -rq "currently colocated" -- "$colocation_status"
        jj -R "$repo_path" git colocation enable
        or begin
            echo "Failed to enable jj/git colocation in $repo_path" >&2
            exit 1
        end
    end

    jj -R "$repo_path" git import >/dev/null
    or begin
        echo "Failed to import git refs into jj for $repo_path" >&2
        exit 1
    end

    set bookmarks (jj -R "$repo_path" bookmark list | sed -n 's/^\([^[:space:]:][^:]*\):.*/\1/p' | sort -u)
    set bookmark_input (printf '%s\n' $bookmarks | fzf --prompt='Bookmark> ' --height=100% --reverse --bind='tab:replace-query,enter:print-query+accept')
    or exit 0

    set bookmark
    for line in $bookmark_input
        set line (string trim -- "$line")
        if test -n "$line"
            set bookmark "$line"
        end
    end
    test -n "$bookmark"; or exit 0

    if not string match -rq '^[A-Za-z0-9._/-]+$' -- "$bookmark"
        echo "Invalid bookmark name: $bookmark" >&2
        exit 1
    end

    set workspace_path "$HOME/Workspaces/$repo_rel/$bookmark"
    set workspace_parent (dirname "$workspace_path")
    set bookmark_exists 0
    if contains -- "$bookmark" $bookmarks
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

        jj -R "$repo_path" git fetch --remote origin --branch main
        or begin
            echo "Failed to fetch origin/main for $repo_path" >&2
            exit 1
        end

        jj -R "$repo_path" log -r 'main@origin' --no-graph --limit 1 >/dev/null 2>&1
        or begin
            echo "Missing main@origin in $repo_path; cannot create workspace base." >&2
            exit 1
        end

        if test $bookmark_exists -eq 1
            set base_rev "$bookmark"
        else
            set base_rev 'main@origin'
        end

        jj -R "$repo_path" workspace forget "$bookmark" >/dev/null 2>&1 || true

        jj -R "$repo_path" workspace add --name "$bookmark" -r "$base_rev" "$workspace_path"
        or begin
            echo "Failed to create workspace at $workspace_path" >&2
            exit 1
        end

        if test $bookmark_exists -eq 0
            jj -R "$workspace_path" bookmark set "$bookmark" -r @
            or begin
                echo "Failed to create bookmark $bookmark in $workspace_path" >&2
                exit 1
            end
        end
    end

    select_agent; or exit 0

    set session_name "$repo_name($bookmark)"

    if tmux has-session -t "$session_name" 2>/dev/null
        tmux switch-client -t "$session_name"
    else
        smug start workspace -a \
            REPO_REL=$repo_rel \
            BOOKMARK=$bookmark \
            SESSION_NAME=$session_name \
            AGENT_CMD=$agent_cmd
    end
    exit 0
end

# --- Worktree ---

if test "$session_type" = Worktree
    command -q git; or exit 0

    set repos (discover_repos)
    test (count $repos) -gt 0; or exit 0

    set repo_rel (printf '%s\n' $repos | fzf --prompt='Worktree> ' --height=100% --reverse)
    or exit 0

    set branch_input (git -C "$HOME/Code/$repo_rel" for-each-ref --format='%(refname:short)' refs/heads refs/remotes/origin \
        | sed -E 's#^origin/##' \
        | grep -v '^HEAD$' \
        | sort -u \
        | fzf --prompt='Branch> ' --height=100% --reverse --bind='tab:replace-query,enter:print-query+accept')
    or exit 0

    set branch
    for line in $branch_input
        set line (string trim -- "$line")
        if test -n "$line"
            set branch "$line"
        end
    end
    test -n "$branch"; or exit 0

    select_agent; or exit 0

    set repo_parts (string split '/' -- $repo_rel)
    if test (count $repo_parts) -ge 1
        set repo_name $repo_parts[-1]
    else
        set repo_name $repo_rel
    end
    set session_name "$repo_name($branch)"

    smug start worktree -a \
        REPO_REL=$repo_rel \
        BRANCH=$branch \
        SESSION_NAME=$session_name \
        AGENT_CMD=$agent_cmd
    exit 0
end
