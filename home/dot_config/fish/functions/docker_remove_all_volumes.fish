function docker_remove_all_volumes
    set -l ids (docker volume ls -q)
    if test (count $ids) -eq 0
        echo "No volumes to remove."
        return 0
    end
    docker volume ls
    # ボリューム削除は不可逆 (データ喪失) のため必ず確認する
    read -l -P "Remove ALL "(count $ids)" volumes? Data will be LOST. [y/N] " ans
    string match -qi y -- $ans; or return 1
    docker volume rm --force $ids
end
