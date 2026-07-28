function docker_remove_all_volumes
    # すべてのボリュームを取得して削除
    docker volume rm (docker volume ls -q) --force
end
