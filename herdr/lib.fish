#!/usr/bin/env fish
# Shared helpers for the Herdr launcher scripts. Sourced, never executed.

function _fail --argument-names msg
    echo "$msg" >&2
    functions -q _trace; and _trace "FAIL: $msg"
    exit 1
end

function _last_non_empty_line
    set -l value
    for line in $argv
        set line (string trim -- "$line")
        if test -n "$line"
            set value "$line"
        end
    end
    test -n "$value"; or return 1
    printf '%s\n' "$value"
end

function _relative_time --argument-names epoch now
    test -n "$now"; or set now (date +%s)
    set -l diff (math "$now - $epoch")
    if test $diff -lt 60
        printf '%ds ago' $diff
    else if test $diff -lt 3600
        printf '%dm ago' (math "floor($diff / 60)")
    else if test $diff -lt 86400
        printf '%dh ago' (math "floor($diff / 3600)")
    else if test $diff -lt 604800
        printf '%dd ago' (math "floor($diff / 86400)")
    else
        printf '%dw ago' (math "floor($diff / 604800)")
    end
end

# Pick from a ranked list. The caller feeds the preferred item first. fzf keeps
# input order while the query is empty, so the cursor starts on that item.
# height and scheme are bare fzf values, for example 100% and path.
function _fzf_pick --argument-names prompt height scheme
    fzf --prompt="$prompt> " --height=$height --reverse --scheme=$scheme \
        --bind='j:down,k:up' $argv[4..-1]
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
