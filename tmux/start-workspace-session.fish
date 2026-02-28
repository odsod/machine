#!/usr/bin/env fish

set -x PATH $HOME/.local/bin /usr/local/bin /usr/bin /bin $PATH

command -q fzf; or exit 0
command -q smug; or exit 0
command -q jj; or exit 0

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

set repos (printf '%s\n' $repos | sort -u)
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

    # Clean stale workspace metadata for this name if path was removed manually.
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

set agent_choice (printf '%s\n' codex gemini claude | fzf --prompt='Agent> ' --height=40% --reverse --bind='j:down,k:up')
or exit 0

set agent_cmd
set agent_bin
switch "$agent_choice"
    case codex
        set agent_cmd codex
        set agent_bin codex
    case gemini
        set agent_cmd gemini
        set agent_bin gemini
    case claude
        set agent_cmd "claude --dangerously-skip-permissions"
        set agent_bin claude
    case '*'
        echo "Unknown agent selection: $agent_choice" >&2
        exit 1
end

command -q "$agent_bin"
or begin
    echo "Selected agent command not found: $agent_bin" >&2
    exit 1
end

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
