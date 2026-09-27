function docker_remove_all_containers
    set -l ids (docker ps -a -q)
    if test (count $ids) -eq 0
        echo "No containers to remove."
        return 0
    end
    docker ps -a
    read -l -P "Remove ALL "(count $ids)" containers? [y/N] " ans
    string match -qi y -- $ans; or return 1
    docker container rm --force $ids
end
