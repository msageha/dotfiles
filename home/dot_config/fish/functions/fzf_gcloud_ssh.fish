function fzf_gcloud_ssh -d "Select a gcloud compute instance and ssh into it"
    type -q gcloud; or begin; echo "fzf_gcloud_ssh: gcloud not found" >&2; return 1; end
    type -q fzf; or begin; echo "fzf_gcloud_ssh: fzf not found" >&2; return 1; end

    set -l selection (gcloud compute instances list \
        --format="value[separator=' '](name, zone.basename())" 2>/dev/null \
        | fzf --prompt="gcloud ssh> ")
    test -n "$selection"; or return

    set -l parts (string split ' ' -- $selection)
    gcloud compute ssh $parts[1] --zone $parts[2]
end
