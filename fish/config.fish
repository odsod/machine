set fish_greeting

# Hostname-specific history
set -x fish_history (string replace -a '-' '_' (hostname))

if not status is-interactive
    return
end

# VS Code / Cursor Shell Integration
if test "$TERM_PROGRAM" = "vscode"
    if type -q code
        set -l integration (code --locate-shell-integration-path fish)
        test -f "$integration"; and source "$integration"
    end
end

abbr -a vim nvim
abbr -a vi nvim
abbr -a cat bat
abbr -a find fd

# Enable Vi mode (Only in standalone terminals)
if not test "$TERM_PROGRAM" = "vscode"
    fish_vi_key_bindings
end

starship init fish | source
fzf --fish | source

# --- Helpers ---

function _fzf_search_files --argument-names mode
    set -l root (git rev-parse --show-toplevel 2>/dev/null)
    if test -z "$root"
        string match -q "$HOME*" $PWD; and set root $HOME; or set root "/"
    end

    set -l cmd "fd --type f --base-directory '$root' --strip-cwd-prefix --exclude .git"
    if test "$mode" = "all"
        set cmd "$cmd --hidden --no-ignore"
    end

    set -x FZF_DEFAULT_COMMAND $cmd
    fzf-file-widget
end

function _fzf_jump_dir --argument-names root prompt mode
    set -l opts --type d --base-directory $root --strip-cwd-prefix --exclude .git
    if test "$mode" = "all"
        set -a opts --hidden --no-ignore
    end

    set -l target (fd $opts | fzf --prompt="$prompt> ")
    if test -n "$target"
        cd "$root/$target"
        # Only switch to insert mode if Vi bindings are active
        if functions -q fish_vi_key_bindings
             if not test "$TERM_PROGRAM" = "vscode"
                set fish_bind_mode insert
            end
        end
        commandline -f repaint
    end
end

function fish_user_key_bindings
    fzf_key_bindings

    # Ctrl-f: Find File (Smart Base) - CLEAN
    bind \cf '_fzf_search_files clean'
    # Bind for Insert mode only if Vi bindings are active
    bind -M insert \cf '_fzf_search_files clean'

    # Alt-f: Find File (Smart Base) - ALL (Hidden + No Ignore)
    bind \ef '_fzf_search_files all'
    bind -M insert \ef '_fzf_search_files all'

    # --- Normal Mode Bindings ---
    # These will only be effective if default/command mode is accessible (i.e. Vi mode)

    # u: Up Directory
    bind -M default u 'cd ..; commandline -f repaint'

    # p: Project Directory Jump (Clean)
    bind -M default p '
        set -l root (git rev-parse --show-toplevel 2>/dev/null); or set root "."
        _fzf_jump_dir $root "Project" clean
    '

    # P: Project Directory Jump (All)
    bind -M default P '
        set -l root (git rev-parse --show-toplevel 2>/dev/null); or set root "."
        _fzf_jump_dir $root "Project" all
    '

    # c: Code Directory Jump (Clean)
    bind -M default c "_fzf_jump_dir $HOME/Code 'Code' clean"

    # C: Code Directory Jump (All)
    bind -M default C "_fzf_jump_dir $HOME/Code 'Code' all"
end

# Colorscheme: Nord
fish_config theme choose Nord
