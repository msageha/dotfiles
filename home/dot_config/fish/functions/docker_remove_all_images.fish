function docker_remove_all_images
    # すべてのローカルイメージを取得して削除
    docker image rm (docker images -q) --force
end
