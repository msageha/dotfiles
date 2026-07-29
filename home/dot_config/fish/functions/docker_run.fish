function docker_run -d 'run and exec docker container'
    set IMAGE $argv[1]
    set CMD "bash"

    if test (count $argv) -gt 1
        set CMD $argv[2..-1]
    end

    set DIR_NAME (basename $PWD)
    # 表示と実行が乖離しないよう、同じリストを echo してから実行する
    set -l docker_cmd docker container run --env DOCKER_MACHINE_NAME=$IMAGE --entrypoint "" -v ./:/tmp/$DIR_NAME -it $IMAGE $CMD
    echo "executing: $docker_cmd"
    $docker_cmd
end
