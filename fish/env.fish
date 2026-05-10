# Fish sources conf.d/*.fish before config.fish. Keep the POSIX env loader here
# so generated integrations like fzf.fish see ~/.local/bin during SSH startup.
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

source_env_sh
