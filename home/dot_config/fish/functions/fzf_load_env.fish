function fzf_load_env
    # 素の .env と .<name>.env の両方に一致させる。-o は暗黙の -a より結合が弱いため括弧でグルーピングする
    set -l env_files (find . -maxdepth 1 \( -name ".env" -o -name ".*.env" \) 2>/dev/null)

    if test (count $env_files) -eq 0
        echo "No .env files found in the current directory."
        return
    end

    # echo だとリストがスペース連結で 1 行になるため、1 要素 1 行で fzf へ渡す
    set -l env_file (printf '%s\n' $env_files | fzf)

    if test -n "$env_file"
        echo "Loading $env_file"
        # bash 形式の KEY=VALUE と export KEY=VALUE の両方に対応
        for line in (grep -vE '^\s*#|^\s*$' $env_file)
            set -l kv (string replace -r '^export\s+' '' -- $line)
            set -l key (string split -m1 '=' -- $kv)[1]
            set -l val (string split -m1 '=' -- $kv)[2]
            if string match -qr '^"' -- $val
                # ダブルクォート値: 閉じクォートまでを値とし、後続 (インラインコメント等) は捨てる
                set val (string replace -r '^"((?:[^"\\\\]|\\\\.)*)".*$' '$1' -- $val)
            else if string match -qr "^'" -- $val
                # シングルクォート値: 同上
                set val (string replace -r "^'([^']*)'.*\$" '$1' -- $val)
            else
                # 非クォート値: インラインコメントを除去して前後の空白を落とす
                set val (string replace -r '\s+#.*$' '' -- $val | string trim)
            end
            if test -n "$key"
                set -gx $key $val
                # .env の値は secret を含みうるためキー名のみ表示する
                echo "  $key"
            end
        end
    else
        echo "No file selected"
    end
end
