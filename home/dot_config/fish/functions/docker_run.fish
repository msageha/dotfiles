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
