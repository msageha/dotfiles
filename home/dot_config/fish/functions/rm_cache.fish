function rm_cache
    # カレントディレクトリ以下のすべての .ruff_cache ディレクトリを検索して削除
    for dir in (find . -type d -name '.ruff_cache')
        echo "Deleting: $dir"
        rm -rf $dir
    end
    # カレントディレクトリ以下のすべての __pycache__ ディレクトリを検索して削除
    for dir in (find . -type d -name '__pycache__')
        echo "Deleting: $dir"
        rm -rf $dir
    end
    # カレントディレクトリ以下のすべての .DS_Store を検索して削除
    for path in (find . -type f -name '.DS_Store')
        echo "Deleting: $path"
        rm -f $path
    end
end
