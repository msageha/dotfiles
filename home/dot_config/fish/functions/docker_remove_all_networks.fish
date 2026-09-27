function docker_remove_all_networks
    # bridge / host / none の pre-defined ネットワークは削除できないため custom のみ対象にする
    set -l ids (docker network ls -q --filter type=custom)
    if test (count $ids) -eq 0
        echo "No custom networks to remove."
        return 0
    end
    docker network ls --filter type=custom
    read -l -P "Remove ALL "(count $ids)" custom networks? [y/N] " ans
    string match -qi y -- $ans; or return 1
    docker network rm --force $ids
end
