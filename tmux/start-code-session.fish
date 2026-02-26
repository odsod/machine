#!/usr/bin/env fish

set -x PATH $HOME/.local/bin /usr/local/bin /usr/bin /bin $PATH

command -q fzf; or exit 0
command -q smug; or exit 0

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

set repo_rel (printf '%s\n' $repos | fzf --prompt='Code> ' --height=40% --reverse)
or exit 0

set repo_parts (string split '/' -- $repo_rel)
set session_name "$repo_parts[2]/$repo_parts[3]"

if tmux has-session -t "$session_name" 2>/dev/null
    tmux switch-client -t "$session_name"
else
    smug start code -a \
        REPO_REL=$repo_rel \
        SESSION_NAME=$session_name
end
