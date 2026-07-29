function rm_cache
    for dir in (find . -type d -name '.ruff_cache')
        echo "Deleting: $dir"
        rm -rf $dir
    end
    for dir in (find . -type d -name '__pycache__')
        echo "Deleting: $dir"
        rm -rf $dir
    end
    for path in (find . -type f -name '.DS_Store')
        echo "Deleting: $path"
        rm -f $path
    end
end
