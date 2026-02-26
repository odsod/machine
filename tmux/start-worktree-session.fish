#!/usr/bin/env fish

set -x PATH $HOME/.local/bin /usr/local/bin /usr/bin /bin $PATH

command -q fzf; or exit 0
command -q gum; or exit 0
command -q smug; or exit 0
command -q git; or exit 0

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

set repo_rel (printf '%s\n' $repos | fzf --prompt='Worktree> ' --height=100% --reverse)
or exit 0

while true
    set branch (gum input --header "$repo_rel" --placeholder BRANCH)
    or exit 0

    set branch (string trim -- $branch)
    if test -n "$branch"
        break
    end
end

set agent_choice (gum choose codex gemini claude)
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
