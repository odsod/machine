#!/usr/bin/env fish

set -x PATH $HOME/.local/bin /usr/local/bin /usr/bin /bin $PATH

command -q gum; or exit 0
command -q smug; or exit 0

set selected (smug list | string trim | string match -rv '^$' | gum choose --header "Start session")
or exit 0

set config_path $HOME/.config/smug/$selected.yml
test -f $config_path; or set config_path $HOME/.config/smug/$selected.yaml

set kv_args
if test -f $config_path
    set vars
    for token in (grep -oE '\$\{[A-Za-z_][A-Za-z0-9_]*(:-[^}]*)?\}' $config_path)
        set name (string match -r '^\$\{(\w+)' $token)[2]
        contains $name $vars; or set -a vars $name
    end
    for name in $vars
        while true
            set value (gum input --header "$selected" --placeholder $name); or exit 0
            if string length -q -- (string trim -- $value)
                set -a kv_args $name=$value
                break
            end
        end
    end
end

smug switch $selected $kv_args
