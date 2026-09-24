# Prevent Python virtualenv activate scripts from altering the prompt
set -gx VIRTUAL_ENV_DISABLE_PROMPT 1

function __prompt_badge -a color text
    set_color D8DEE9
    echo -n " ["
    set_color $color
    echo -n "$text"
    set_color D8DEE9
    echo -n "]"
end

function fish_prompt
    set -l last_status $status
    set -l last_duration $CMD_DURATION

    # Line 1: empty line before prompt
    echo

    # Directory
    set_color EBCB8B
    echo -n (string replace -r "^$HOME" '~' "$PWD")

    # Jujutsu status (or Git if not in a jj repo)
    set -l dir "$PWD"
    set -l in_jj 0
    while test -n "$dir" -a "$dir" != "/"
        if test -d "$dir/.jj"
            set in_jj 1
            break
        end
        set dir (string match -r '^(.+)/[^/]*$' $dir)[2]
    end

    if test $in_jj -eq 1
        set -l jj_out (jj log -r @ --no-graph --ignore-working-copy -T 'separate(" ", change_id.shortest(8), bookmarks.map(|b| b.name()).join(" "), if(conflict, "[×]"), if(description == "", "[∅]"))' 2>/dev/null)
        if test -n "$jj_out"
            __prompt_badge 81A1C1 " $jj_out"
        end
    else
        set -l dir "$PWD"
        set -l in_git 0
        while test -n "$dir" -a "$dir" != "/"
            if test -d "$dir/.git"
                set in_git 1
                break
            end
            set dir (string match -r '^(.+)/[^/]*$' $dir)[2]
        end
        if test $in_git -eq 1
            set -l git_branch (git branch --show-current 2>/dev/null; or git rev-parse --short HEAD 2>/dev/null)
            if test -n "$git_branch"
                __prompt_badge 81A1C1 " $git_branch"
            end
        end
    end

    # Direnv
    if test -n "$DIRENV_FILE"
        __prompt_badge D08770 (path basename $DIRENV_FILE)
    end

    # Python virtualenv
    if test -n "$VIRTUAL_ENV"
        __prompt_badge A3BE8C " "(path basename $VIRTUAL_ENV)
    end

    # Terraform workspace
    set -l tf_ws ""
    if test -n "$TF_WORKSPACE"
        set tf_ws "$TF_WORKSPACE"
    else if test -f .terraform/environment
        read -l line < .terraform/environment
        set tf_ws "$line"
    end
    if test -n "$tf_ws" -a "$tf_ws" != "default"
        __prompt_badge B48EAD " $tf_ws"
    end

    # Gcloud active project
    set -l gcloud_proj ""
    if test -n "$CLOUDSDK_CORE_PROJECT"
        set gcloud_proj "$CLOUDSDK_CORE_PROJECT"
    else if test -f ~/.config/gcloud/active_config
        read -l cfg < ~/.config/gcloud/active_config
        if test -n "$cfg" -a -f ~/.config/gcloud/configurations/config_$cfg
            while read -l line
                if string match -q "project = *" -- $line
                    set gcloud_proj (string split " = " -- $line)[2]
                    break
                end
            end < ~/.config/gcloud/configurations/config_$cfg
        end
    end
    if test -n "$gcloud_proj"
        __prompt_badge 81A1C1 "󱇶  $gcloud_proj"
    end

    # Docker context
    set -l d_ctx ""
    if test -n "$DOCKER_CONTEXT"
        set d_ctx "$DOCKER_CONTEXT"
    else if test -f ~/.docker/config.json
        set -l match (string match -r '"currentContext"\s*:\s*"([^"]+)"' < ~/.docker/config.json)
        if test -n "$match[2]"
            set d_ctx "$match[2]"
        end
    end
    if test -n "$d_ctx" -a "$d_ctx" != "default"
        __prompt_badge 88C0D0 " $d_ctx"
    end

    # Execution duration (>= 2000 ms)
    if test -n "$last_duration" -a "$last_duration" -ge 2000
        set -l dur ""
        if test $last_duration -ge 60000
            set -l m (math --scale=0 "$last_duration / 60000")
            set -l s (math --scale=0 "($last_duration % 60000) / 1000")
            set dur "$m"m" $s"s
        else
            set -l s (math --scale=0 "$last_duration / 1000")
            set dur "$s"s
        end
        __prompt_badge EBCB8B "took $dur"
    end

    # Line 2: Character with Vi mode and status indicator
    echo
    switch "$fish_bind_mode"
        case default
            set_color D8DEE9
            echo -n ": "
        case visual
            set_color D8DEE9
            echo -n "% "
        case replace replace_one
            set_color D8DEE9
            echo -n "+ "
        case '*'
            if test $last_status -eq 0
                set_color D8DEE9
                echo -n "\$ "
            else
                set_color BF616A
                echo -n "\$ "
            end
    end
    set_color normal
end

# Empty fish_mode_prompt so mode indicator is not duplicated
function fish_mode_prompt
end

# Repaint prompt character immediately when switching vi modes
function __fish_repaint_on_bind_mode --on-variable fish_bind_mode
    test "$fish_bind_mode" != "$__fish_prev_bind_mode"; or return
    set -g __fish_prev_bind_mode "$fish_bind_mode"
    commandline -f repaint 2>/dev/null
end
