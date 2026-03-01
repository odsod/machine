set fish_greeting
set -g fish_history (string replace -a '-' '_' (hostname))

status is-interactive; or return
set -q CURSOR_AGENT; and return

abbr -a vim nvim
abbr -a vi nvim
abbr -a cat bat
abbr -a find fd
abbr -a claude 'claude --dangerously-skip-permissions'

set -g fish_key_bindings fish_vi_key_bindings

# Cursor shapes for VI mode
set -g fish_cursor_default block blink
set -g fish_cursor_insert line blink
set -g fish_cursor_replace_one underscore blink
set -g fish_cursor_visual block blink

# Keep theme state in repo config (avoid fish_frozen_theme.fish drift).
set --global fish_color_autosuggestion brblack
set --global fish_color_cancel --reverse
set --global fish_color_command brcyan
set --global fish_color_comment brblack --italics
set --global fish_color_cwd brblue
set --global fish_color_cwd_root brred
set --global fish_color_end brblue
set --global fish_color_error brred
set --global fish_color_escape bryellow
set --global fish_color_history_current brwhite --bold
set --global fish_color_host brgreen
set --global fish_color_host_remote
set --global fish_color_keyword
set --global fish_color_match --background=brblue
set --global fish_color_normal normal
set --global fish_color_operator brblue
set --global fish_color_option
set --global fish_color_param white
set --global fish_color_quote brgreen
set --global fish_color_redirection brmagenta --bold
set --global fish_color_search_match --bold --reverse
set --global fish_color_selection white --bold --reverse
set --global fish_color_status red
set --global fish_color_user brgreen
set --global fish_color_valid_path --underline
set --global fish_pager_color_background
set --global fish_pager_color_completion brwhite
set --global fish_pager_color_description bryellow --italics
set --global fish_pager_color_prefix normal --bold --underline
set --global fish_pager_color_progress normal --background=yellow
set --global fish_pager_color_secondary_background
set --global fish_pager_color_secondary_completion
set --global fish_pager_color_secondary_description
set --global fish_pager_color_secondary_prefix
set --global fish_pager_color_selected_background --reverse
set --global fish_pager_color_selected_completion
set --global fish_pager_color_selected_description
set --global fish_pager_color_selected_prefix

function source_env_sh --argument-names env_file
    set -q env_file[1]; or set env_file "$HOME/.profile"
    test -f "$env_file"; or return 1

    for entry in (env -i HOME="$HOME" USER="$USER" PATH="/usr/bin:/bin" sh -c '. "$1" >/dev/null 2>&1; env -0' sh "$env_file" | string split0)
        set -l parts (string split -m 1 '=' -- $entry)
        set -l key $parts[1]
        set -l value $parts[2]

        switch $key
            case PWD OLDPWD SHLVL _
                continue
        end

        set -gx $key $value
    end
end

function _fzf_search_files --argument-names mode
    set -l root (git rev-parse --show-toplevel 2>/dev/null); or set root "."
    set -l cmd "fd --type f --base-directory '$root' --strip-cwd-prefix --exclude .git"
    test "$mode" = all; and set cmd "$cmd --hidden --no-ignore"

    set -lx FZF_DEFAULT_COMMAND $cmd
    fzf-file-widget
end

function _fzf_jump_dir --argument-names root prompt mode
    set -l opts --type d --base-directory $root --strip-cwd-prefix --exclude .git
    test "$mode" = all; and set -a opts --hidden --no-ignore

    set -l target (fd $opts | fzf --prompt="$prompt> " --height=100% --reverse)
    if test -n "$target"
        cd "$root/$target"
        functions -q fish_vi_key_bindings; and set fish_bind_mode insert
        commandline -f repaint
    end
end

function fish_user_key_bindings
    fzf_key_bindings

    # Vi mode: keep Home/End behavior aligned with newer fish defaults.
    bind -M default \e\[H beginning-of-line
    bind -M default \eOH beginning-of-line
    bind -M default \e\[F end-of-line
    bind -M default \eOF end-of-line

    # FZF Search (Clean / All)
    bind \ct '_fzf_search_files clean'
    bind -M insert \ct '_fzf_search_files clean'
    bind \et '_fzf_search_files all'
    bind -M insert \et '_fzf_search_files all'

    # Readline Navigation
    bind -M insert \ca beginning-of-line
    bind -M insert \ce end-of-line
    bind -M insert \cf forward-char
    bind -M insert \t 'commandline -f complete' # Tab for completion only (Use Ctrl-f/Right Arrow for autosuggestion)
    bind -M insert \cb backward-char
    bind -M insert \ef forward-word
    bind -M insert \eb backward-word
    bind -M insert \ck kill-line
    bind -M insert \cd delete-or-exit
    bind -M insert \cp up-or-search
    bind -M insert \cn down-or-search

    # Vim Normal Mode: Go [Up|Project|Code]
    bind -M default gu 'cd ..; commandline -f repaint'
    bind -M default gg 'cd (git rev-parse --show-toplevel 2>/dev/null; or echo .); commandline -f repaint'

    bind -M default gp 'set -l r (git rev-parse --show-toplevel 2>/dev/null); or set r "."; _fzf_jump_dir $r "Project" clean'
    bind -M default gP 'set -l r (git rev-parse --show-toplevel 2>/dev/null); or set r "."; _fzf_jump_dir $r "Project" all'

    bind -M default gc "_fzf_jump_dir $HOME/Code 'Code' clean"
    bind -M default gC "_fzf_jump_dir $HOME/Code 'Code' all"

    bind -M default gw "_fzf_jump_dir $HOME/Worktrees 'Worktree' clean"
    bind -M default gW "_fzf_jump_dir $HOME/Worktrees 'Worktree' all"
end
