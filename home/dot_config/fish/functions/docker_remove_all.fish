function docker_remove_all -d 'Remove ALL docker containers / images / networks / volumes after confirmation'
    set -l kind $argv[1]
    set -l list_cmd
    set -l rm_cmd
    set -l label
    set -l warning
    switch "$kind"
        case containers
            set list_cmd docker ps -a
            set rm_cmd docker container rm --force
            set label containers
        case images
            set list_cmd docker images
            set rm_cmd docker image rm --force
            set label images
        case networks
            # bridge / host / none の pre-defined ネットワークは削除できないため custom のみ対象にする
            set list_cmd docker network ls --filter type=custom
            set rm_cmd docker network rm --force
            set label "custom networks"
        case volumes
            set list_cmd docker volume ls
            set rm_cmd docker volume rm --force
            set label volumes
            # ボリューム削除は不可逆 (データ喪失) のため確認文で明示する
            set warning " Data will be LOST."
        case '*'
            echo "usage: docker_remove_all <containers|images|networks|volumes>" >&2
            return 2
    end

    set -l ids ($list_cmd -q)
    if test (count $ids) -eq 0
        echo "No $label to remove."
        return 0
    end
    $list_cmd
    read -l -P "Remove ALL "(count $ids)" $label?$warning [y/N] " ans
    string match -qi y -- $ans; or return 1
    $rm_cmd $ids
end
