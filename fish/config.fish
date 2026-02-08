set fish_greeting

# Hostname-specific history
set -x fish_history (string replace -a '-' '_' (hostname))

if not status is-interactive
    return
end

abbr -a vim nvim
abbr -a vi nvim
abbr -a cat bat
abbr -a find fd

# Enable Vi mode
fish_vi_key_bindings

starship init fish | source
fzf --fish | source

# Bindings
function fish_user_key_bindings
    fzf_key_bindings

    # --- Global Bindings (Insert & Normal) ---
    
    # Ctrl-f: Find File (Smart Base) - CLEAN
    set -l find_file_clean '
        set -l root (git rev-parse --show-toplevel 2>/dev/null)
        if test -z "$root"
            string match -q "$HOME*" $PWD; and set root $HOME; or set root "/"
        end
        set -x FZF_DEFAULT_COMMAND "fd --type f --base-directory $root --strip-cwd-prefix --exclude .git"
        fzf-file-widget
    '
    bind \cf $find_file_clean
    bind -M insert \cf $find_file_clean

    # Alt-f: Find File (Smart Base) - ALL (Hidden + No Ignore)
    set -l find_file_all '
        set -l root (git rev-parse --show-toplevel 2>/dev/null)
        if test -z "$root"
            string match -q "$HOME*" $PWD; and set root $HOME; or set root "/"
        end
        set -x FZF_DEFAULT_COMMAND "fd --type f --base-directory $root --strip-cwd-prefix --hidden --no-ignore --exclude .git"
        fzf-file-widget
    '
    bind \ef $find_file_all
    bind -M insert \ef $find_file_all

    # --- Normal Mode Bindings ---

    # u: Up Directory
    bind -M default u 'cd ..; commandline -f repaint'

    # p: Project Directory Jump (Clean)
    # Logic: Nearest Git Root -> Current Dir
    bind -M default p '
        set -l root (git rev-parse --show-toplevel 2>/dev/null)
        if test -z "$root"
            set root "."
        end
        set -l target (fd --type d --base-directory "$root" --strip-cwd-prefix --exclude .git | fzf --prompt="Project CD> ")
        if test -n "$target"
            cd "$root/$target"
            commandline -f repaint
        end
    '

    # P: Project Directory Jump (All - Hidden + Ignored)
    # Logic: Nearest Git Root -> Current Dir
    bind -M default P '
        set -l root (git rev-parse --show-toplevel 2>/dev/null)
        if test -z "$root"
            set root "."
        end
        set -l target (fd --type d --base-directory "$root" --strip-cwd-prefix --hidden --no-ignore --exclude .git | fzf --prompt="Project ALL> ")
        if test -n "$target"
            cd "$root/$target"
            commandline -f repaint
        end
    '

    # c: Code Directory Jump (Clean)
    bind -M default c '
        set -l target (fd --type d --base-directory $HOME/Code --strip-cwd-prefix --exclude .git | fzf --prompt="Code CD> ")
        if test -n "$target"
            cd "$HOME/Code/$target"
            commandline -f repaint
        end
    '

    # C: Code Directory Jump (All - Hidden + Ignored)
    bind -M default C '
        set -l target (fd --type d --base-directory $HOME/Code --strip-cwd-prefix --hidden --no-ignore --exclude .git | fzf --prompt="Code ALL> ")
        if test -n "$target"
            cd "$HOME/Code/$target"
            commandline -f repaint
        end
    '
end

# Colorscheme: Nord
fish_config theme choose Nord
