function docker_remove_all_containers
    # すべてのコンテナを取得して削除
    docker container rm (docker ps -a -q) --force
end
