set fish_greeting
set -x fish_history (string replace -a '-' '_' (hostname))

status is-interactive; or return
set -q CURSOR_AGENT; and return

abbr -a vim nvim
abbr -a vi nvim
abbr -a cat bat
abbr -a find fd

fish_vi_key_bindings
starship init fish | source
fzf --fish | source
fish_config theme choose Nord

function _fzf_search_files --argument-names mode
    set -l root (git rev-parse --show-toplevel 2>/dev/null); or set root "."
    set -l cmd "fd --type f --base-directory '$root' --strip-cwd-prefix --exclude .git"
    test "$mode" = "all"; and set cmd "$cmd --hidden --no-ignore"

    set -x FZF_DEFAULT_COMMAND $cmd
    fzf-file-widget
end

function _fzf_jump_dir --argument-names root prompt mode
    set -l opts --type d --base-directory $root --strip-cwd-prefix --exclude .git
    test "$mode" = "all"; and set -a opts --hidden --no-ignore

    set -l target (fd $opts | fzf --prompt="$prompt> ")
    if test -n "$target"
        cd "$root/$target"
        functions -q fish_vi_key_bindings; and set fish_bind_mode insert
        commandline -f repaint
    end
end

function fish_user_key_bindings
    fzf_key_bindings

    # FZF Search (Clean / All)
    bind \ct '_fzf_search_files clean'
    bind -M insert \ct '_fzf_search_files clean'
    bind \et '_fzf_search_files all'
    bind -M insert \et '_fzf_search_files all'

    # Readline Navigation
    bind -M insert \ca beginning-of-line
    bind -M insert \ce end-of-line
    bind -M insert \cf forward-char
    bind -M insert \cb backward-char
    bind -M insert \ef forward-word
    bind -M insert \eb backward-word
    bind -M insert \ck kill-line
    bind -M insert \cd delete-or-exit
    bind -M insert \cp up-or-search
    bind -M insert \cn down-or-search

    # Vim Normal Mode: Go [Up|Project|Code]
    bind -M default gu 'cd ..; commandline -f repaint'

    bind -M default gp 'set -l r (git rev-parse --show-toplevel 2>/dev/null); or set r "."; _fzf_jump_dir $r "Project" clean'
    bind -M default gP 'set -l r (git rev-parse --show-toplevel 2>/dev/null); or set r "."; _fzf_jump_dir $r "Project" all'

    bind -M default gc "_fzf_jump_dir $HOME/Code 'Code' clean"
    bind -M default gC "_fzf_jump_dir $HOME/Code 'Code' all"
end
