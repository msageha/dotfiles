function fzf_gcloud_auth -d "Select and activate a gcloud account"
    type -q gcloud; or begin; echo "fzf_gcloud_auth: gcloud not found" >&2; return 1; end
    type -q fzf; or begin; echo "fzf_gcloud_auth: fzf not found" >&2; return 1; end

    set -l account (gcloud auth list --format="value(account)" | fzf)
    if test -n "$account"
        gcloud config set account "$account"
    end
end
