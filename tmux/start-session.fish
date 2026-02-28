#!/usr/bin/env fish

set -x PATH $HOME/.local/bin /usr/local/bin /usr/bin /bin $PATH

command -q fzf; or exit 0

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

# --- Session launcher ---

function _launch_session
    set session_name $argv[1]
    set session_root $argv[2]
    set agent_cmd $argv[3]

    if tmux has-session -t $session_name 2>/dev/null
        tmux switch-client -t $session_name
    else
        tmux new-session -d -s $session_name -c $session_root -n editor
        tmux send-keys -t "$session_name:editor" $agent_cmd Enter
        tmux switch-client -t $session_name
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
              --print-query --bind='tab:replace-query')
    test $status -ne 130; or exit 0

    set dir_name (string trim -- $chosen[-1])
    test -n "$dir_name"; or exit 0

    set session_root "$HOME/Activities/$dir_name"
    mkdir -p "$session_root"

    select_agent; or exit 0

    set session_name "$dir_name"

    _launch_session $session_name $session_root $agent_cmd
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
              --print-query --bind='tab:replace-query')
    test $status -ne 130; or exit 0

    set dir_name (string trim -- $chosen[-1])
    test -n "$dir_name"; or exit 0

    set session_root "$HOME/Projects/$dir_name"
    mkdir -p "$session_root"

    select_agent; or exit 0

    set session_name "$dir_name"

    _launch_session $session_name $session_root $agent_cmd
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

    _launch_session $session_name "$HOME/Code/$repo_rel" $agent_cmd
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
    set bookmark_input (printf '%s\n' $bookmarks \
        | fzf --prompt='Bookmark> ' --height=100% --reverse \
              --print-query --bind='tab:replace-query')
    test $status -ne 130; or exit 0

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

    _launch_session $session_name "$HOME/Workspaces/$repo_rel/$bookmark" $agent_cmd
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
        | fzf --prompt='Branch> ' --height=100% --reverse \
              --print-query --bind='tab:replace-query')
    test $status -ne 130; or exit 0

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
    set expected_worktree_path "$HOME/Worktrees/$repo_rel/$branch"
    set worktree_path "$expected_worktree_path"
    set existing_worktree_path (
        git -C "$HOME/Code/$repo_rel" worktree list --porcelain \
        | awk -v target="refs/heads/$branch" '
            $1 == "worktree" { path = $2 }
            $1 == "branch" && $2 == target { print path; exit }
        '
    )
    if test -n "$existing_worktree_path"
        set worktree_path "$existing_worktree_path"
    end

    mkdir -p "$HOME/Worktrees/$repo_rel"
    git -C "$HOME/Code/$repo_rel" fetch --prune origin 2>/dev/null; or true

    if not git -C "$worktree_path" rev-parse --is-inside-work-tree >/dev/null 2>&1
        if git -C "$HOME/Code/$repo_rel" show-ref --verify --quiet "refs/heads/$branch"
            git -C "$HOME/Code/$repo_rel" worktree add "$expected_worktree_path" "$branch"
        else if git -C "$HOME/Code/$repo_rel" show-ref --verify --quiet "refs/remotes/origin/$branch"
            git -C "$HOME/Code/$repo_rel" worktree add --track -b "$branch" "$expected_worktree_path" "origin/$branch"
        else
            git -C "$HOME/Code/$repo_rel" worktree add -b "$branch" "$expected_worktree_path" HEAD
        end

        if not git -C "$expected_worktree_path" rev-parse --is-inside-work-tree >/dev/null 2>&1
            set existing_worktree_path (
                git -C "$HOME/Code/$repo_rel" worktree list --porcelain \
                | awk -v target="refs/heads/$branch" '
                    $1 == "worktree" { path = $2 }
                    $1 == "branch" && $2 == target { print path; exit }
                '
            )
            if test -n "$existing_worktree_path"
                set worktree_path "$existing_worktree_path"
            else
                echo "Failed to create/find worktree for branch: $branch" >&2
                exit 1
            end
        else
            set worktree_path "$expected_worktree_path"
        end
    end

    if test "$worktree_path" = "$expected_worktree_path"; and git -C "$HOME/Code/$repo_rel" show-ref --verify --quiet "refs/remotes/origin/$branch"
        git -C "$worktree_path" checkout -B "$branch" "origin/$branch"
        git -C "$worktree_path" clean -fd
        git -C "$worktree_path" reset --hard "origin/$branch"
    end

    if not git -C "$worktree_path" rev-parse --is-inside-work-tree >/dev/null 2>&1
        echo "Resolved path is not a git worktree: $worktree_path" >&2
        exit 1
    end

    _launch_session $session_name $worktree_path $agent_cmd
    exit 0
end
