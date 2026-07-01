function docker_run -d 'run and exec docker container'
    set IMAGE $argv[1]  # 第一引数をイメージ名として取得
    set CMD "bash"      # デフォルトのコマンドは bash に設定

    # 第二引数が存在すれば、それをコマンドとして設定
    if test (count $argv) -gt 1
        set CMD $argv[2..-1]
    end

    echo "executing: docker container run -it $IMAGE $CMD"
    set DIR_NAME (basename $PWD)
    docker container run --env DOCKER_MACHINE_NAME=$IMAGE --entrypoint "" -v ./:/tmp/$DIR_NAME -it $IMAGE $CMD
end

function docker_remove_all_images
    # すべてのローカルイメージを取得して削除
    docker image rm (docker images -q) --force
end

function docker_remove_all_containers
    # すべてのコンテナを取得して削除
    docker container rm (docker ps -a -q) --force
end

function docker_remove_all_volumes
    # すべてのボリュームを取得して削除
    docker volume rm (docker volume ls -q) --force
end

function docker_remove_all_networks
    # すべてのネットワークを取得して削除
    docker network rm (docker network ls -q) --force
end
