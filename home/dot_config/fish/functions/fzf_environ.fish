function fzf_load_env
    set -l env_files (find . -maxdepth 1 -name ".*.env" 2>/dev/null)

    if test (count $env_files) -eq 0
        echo "No .env files found in the current directory."
        return
    end

    set -l env_file (echo $env_files | fzf)

    if test -n "$env_file"
        echo "Loading $env_file"
        # bash 形式の KEY=VALUE と export KEY=VALUE の両方に対応
        for line in (grep -vE '^\s*#|^\s*$' $env_file)
            set -l kv (string replace -r '^export\s+' '' -- $line)
            set -l key (string split -m1 '=' -- $kv)[1]
            set -l val (string split -m1 '=' -- $kv)[2]
            # クォートされていない場合はインラインコメントを除去
            if not string match -qr '^["\x27]' -- $val
                set val (string replace -r '\s+#.*$' '' -- $val)
            end
            # クォートを除去
            set val (string trim -c '"' -- $val)
            set val (string trim -c "'" -- $val)
            if test -n "$key"
                set -gx $key $val
                echo "  $key=$val"
            end
        end
    else
        echo "No file selected"
    end
end
