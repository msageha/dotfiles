function docker_run -d 'Run a shell (or command) in a container with the current directory mounted'
    set -l image $argv[1]
    set -l cmd bash

    if test (count $argv) -gt 1
        set cmd $argv[2..-1]
    end

    set -l dir_name (basename $PWD)
    # 表示と実行が乖離しないよう、同じリストを echo してから実行する
    set -l docker_cmd docker container run --env DOCKER_MACHINE_NAME=$image --entrypoint "" -v ./:/tmp/$dir_name -it $image $cmd
    echo "executing: $docker_cmd"
    $docker_cmd
end
