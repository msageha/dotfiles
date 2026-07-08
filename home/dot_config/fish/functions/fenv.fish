function fenv -d "Select and load mise/fnox environment for the current directory"
    if not type -q fzf
        echo "fzf is required."
        return 1
    end

    set -l candidates default

    for env_file in mise.*.toml fnox.*.toml
        test -f "$env_file"; or continue
        set -l name (string replace -r '^(mise|fnox)\.' '' -- "$env_file" | string replace -r '\.toml$' '')
        contains -- "$name" $candidates; or set -a candidates "$name"
    end

    set -l selected (printf '%s\n' $candidates | sort -u | fzf --select-1 --prompt='env> ')
    if test -z "$selected"
        return 1
    end

    if type -q mise; and test -f mise.toml
        if test "$selected" = default
            mise env -s fish | source
        else
            mise -E "$selected" env -s fish | source
        end
    else if type -q mise; and test -f mise.$selected.toml
        mise -E "$selected" env -s fish | source
    end

    __fenv_load_fnox "$selected"
end

function __fenv_load_fnox
    set -l selected "$argv[1]"
    type -q fnox; or return 0

    if test "$selected" = default
        test -f fnox.toml; or return 0
    else
        test -f fnox.toml; or test -f fnox.$selected.toml; or return 0
    end

    set -l temp_dir (mktemp -d)
    if test -z "$temp_dir"
        echo "Failed to create temporary directory."
        return 1
    end

    set -l profile_args
    if test -f fnox.toml
        cp fnox.toml "$temp_dir/fnox.toml"
        if test "$selected" != default; and test -f fnox.$selected.toml
            cp fnox.$selected.toml "$temp_dir/fnox.$selected.toml"
            set profile_args -P "$selected"
        end
    else if test "$selected" != default; and test -f fnox.$selected.toml
        cp fnox.$selected.toml "$temp_dir/fnox.toml"
    end

    set -l prompt_auth true
    if functions -q __fnox_preauth_1password
        if not __fnox_preauth_1password
            set prompt_auth false
        end
    end

    set -l fnox_output
    if test "$prompt_auth" = true
        set fnox_output (fnox -c "$temp_dir/fnox.toml" $profile_args export -f env 2>/dev/null)
    else
        set fnox_output (FNOX_PROMPT_AUTH=false fnox -c "$temp_dir/fnox.toml" $profile_args export -f env 2>/dev/null)
    end
    set -l fnox_status $status
    rm -rf "$temp_dir"

    if test $fnox_status -ne 0
        echo "Failed to load fnox environment."
        return $fnox_status
    end

    for line in $fnox_output
        string match -qr '^[A-Za-z_][A-Za-z0-9_]*=' -- "$line"; or continue
        set -l key (string split -m1 '=' -- "$line")[1]
        set -l val (string split -m1 '=' -- "$line")[2]
        set -gx $key "$val"
    end
end
