function fzf_gcloud_ssh -d "List and ssh into a gcloud compute instance"
    if not type -q gcloud
        echo "fzf_gcloud_ssh: gcloud not found" >&2
        return 1
    end

    set -l selection (gcloud compute instances list \
        --format="value[separator=' '](name, zone.basename())" 2>/dev/null \
        | fzf --prompt="gcloud ssh> ")
    test -n "$selection"; or return

    set -l parts (string split ' ' -- $selection)
    gcloud compute ssh $parts[1] --zone $parts[2]
end
