function fenv -d "カレントディレクトリの mise / fnox の環境を選んで読み込む"
    if not type -q fzf
        echo "fenv: fzf not found" >&2
        return 1
    end

    # mise.<env>.toml・mise.<env>.local.toml は環境 <env> の、fnox.<profile>.toml は profile <profile> の設定
    set -l candidates default
    for env_file in mise.*.toml
        test -f "$env_file"; and set -a candidates (string replace -r '^mise\.(.+?)(\.local)?\.toml$' '$1' -- "$env_file")
    end
    for env_file in fnox.*.toml
        test -f "$env_file"; and set -a candidates (string replace -r '^fnox\.(.+)\.toml$' '$1' -- "$env_file")
    end
    # fnox の設定の [profiles.<profile>] で定義した profile はファイルを持たないので、fnox から名前を取る
    set -a candidates (__fenv_fnox_inline_profiles)

    # mise.local.toml と fnox.local.toml は環境によらず読まれるので、local は候補にしない
    set -l selected (string match -v local -- $candidates | sort -u | fzf --select-1 --prompt='env> ')
    if test -z "$selected"
        return 1
    end

    if type -q mise; and path is -f mise.toml mise.local.toml mise.$selected.toml mise.$selected.local.toml
        if test "$selected" = default
            mise env -s fish | source
        else
            mise -E "$selected" env -s fish | source
        end
    end

    __fenv_load_fnox "$selected"
end
