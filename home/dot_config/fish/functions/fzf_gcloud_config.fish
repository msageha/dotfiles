function fzf_gcloud_config -d "List gcloud config configurations"
    if not type -q gcloud
        echo "fzf_gcloud_config: gcloud not found" >&2
        return 1
    end
    if not type -q fzf
        echo "fzf_gcloud_config: fzf not found" >&2
        return 1
    end

    set -l config (gcloud config configurations list \
        | awk '{ print $1,$3,$4 }' \
        | column -t \
        | fzf --header-lines=1 \
        | awk '{ print $1 }')
    if test -n "$config"
        gcloud config configurations activate "$config"
    end
end
