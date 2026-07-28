function docker_remove_all_networks
    # すべてのネットワークを取得して削除
    docker network rm (docker network ls -q) --force
end
