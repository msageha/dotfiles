function __tool_path -d 'コマンドの実体パスを出す (PATH に無ければ mise which で探す)'
    # mise activate より前に呼ぶと、mise だけで入れたツールは PATH に無い
    if not command -v $argv[1] 2>/dev/null
        type -q mise; and mise which $argv[1] 2>/dev/null
    end
end
