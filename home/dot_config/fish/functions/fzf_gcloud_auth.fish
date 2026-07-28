function fzf_gcloud_auth -d "List gcloud auth"
    if not type -q gcloud
        echo "fzf_gcloud_auth: gcloud not found" >&2
        return 1
    end
    if not type -q fzf
        echo "fzf_gcloud_auth: fzf not found" >&2
        return 1
    end

    set -l account (gcloud auth list --format="value(account)" | fzf)
    if test -n "$account"
        gcloud config set account "$account"
    end
end
