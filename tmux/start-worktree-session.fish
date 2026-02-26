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

set repo_rel (printf '%s\n' $repos | fzf --prompt='Repo> ' --height=40% --reverse)
or exit 0

while true
    set branch (gum input --header "$repo_rel" --placeholder BRANCH)
    or exit 0

    set branch (string trim -- $branch)
    if test -n "$branch"
        break
    end
end

set repo_parts (string split '/' -- $repo_rel)
if test (count $repo_parts) -ge 3
    set session_name "$repo_parts[2]-$repo_parts[3]"
else
    set session_name (string replace -a '/' '-' -- $repo_rel)
end
set branch_slug (string replace -a '/' '-' -- $branch)
set session_name "$session_name-$branch_slug"
set session_name (string replace -a -r -- '[^A-Za-z0-9_-]' '-' $session_name)
set session_name (string replace -a -r -- '--+' '-' $session_name)
set session_name (string trim -c '-' -- $session_name)

smug start worktree -a \
    REPO_REL=$repo_rel \
    BRANCH=$branch \
    SESSION_NAME=$session_name
