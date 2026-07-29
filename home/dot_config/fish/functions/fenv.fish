function fenv -d "Select and load mise/fnox environment for the current directory"
    if not type -q fzf
        echo "fzf is required."
        return 1
    end

    set -l candidates default

    for env_file in mise.*.toml fnox.*.toml
        test -f "$env_file"; or continue
        set -l name (string replace -r '^(mise|fnox)\.' '' -- "$env_file" | string replace -r '\.toml$' '')
        # *.local.toml は環境ではなくマシンローカルの overlay ファイルなので候補にしない
        test "$name" = local; and continue
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
