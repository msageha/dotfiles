function fzf_gcloud_config -d "List gcloud config configurations"
    set -l config (gcloud config configurations list \
        | awk '{ print $1,$3,$4 }' \
        | column -t \
        | fzf --header-lines=1 \
        | awk '{ print $1 }')
    if test -n "$config"
        gcloud config configurations activate "$config"
    end
end
