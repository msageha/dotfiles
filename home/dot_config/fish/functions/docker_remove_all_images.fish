function docker_remove_all_images
    set -l ids (docker images -q)
    if test (count $ids) -eq 0
        echo "No images to remove."
        return 0
    end
    docker images
    read -l -P "Remove ALL "(count $ids)" images? [y/N] " ans
    string match -qi y -- $ans; or return 1
    docker image rm --force $ids
end
