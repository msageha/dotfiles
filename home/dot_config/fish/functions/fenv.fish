function fenv -d "カレントディレクトリの mise / fnox の環境を選んで読み込む"
    if not type -q fzf
        echo "fenv: fzf not found" >&2
        return 1
    end

    set -l candidates default

    for env_file in mise.*.toml fnox.*.toml
        test -f "$env_file"; or continue
        # mise.local.toml・fnox.local.toml は環境によらず読まれる上書きなので候補にせず、mise.<env>.local.toml は <env> として扱う
        set -l name (string replace -r '^(mise|fnox)\.(.+)\.toml$' '$2' -- "$env_file" | string replace -r '(^|\.)local$' '')
        test -n "$name"; or continue
        contains -- "$name" $candidates; or set -a candidates "$name"
    end
    # fnox.toml の中で定義した profile はファイルを持たないので、fnox から名前を取る
    set -a candidates (__fenv_fnox_inline_profiles)

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
