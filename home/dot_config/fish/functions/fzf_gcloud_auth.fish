function fzf_gcloud_auth -d "List gcloud auth"
    set -l account (gcloud auth list --format="value(account)" | fzf)
    if test -n "$account"
        gcloud config set account "$account"
    end
end
