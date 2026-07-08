function faws -d "Select and activate an aws-vault profile"
    if not type -q aws-vault
        echo "aws-vault is required."
        return 1
    end
    if not type -q fzf
        echo "fzf is required."
        return 1
    end

    set -l profile (aws-vault list \
        | awk 'NR > 2 && $1 !~ /^=+$/ { print $1 }' \
        | fzf --select-1 --prompt='aws> ')

    if test -z "$profile"
        return 1
    end

    set -e AWS_ACCESS_KEY_ID
    set -e AWS_SECRET_ACCESS_KEY
    set -e AWS_SESSION_TOKEN
    set -e AWS_SECURITY_TOKEN
    set -e AWS_CREDENTIAL_EXPIRATION
    set -e AWS_PROFILE
    set -e AWS_DEFAULT_PROFILE
    set -e AWS_REGION
    set -e AWS_DEFAULT_REGION
    set -e AWS_VAULT

    set -l aws_env (aws-vault exec "$profile" -- env 2>/dev/null)
    set -l aws_vault_status $status
    if test $aws_vault_status -ne 0
        echo "Failed to activate aws-vault profile: $profile"
        return $aws_vault_status
    end

    for line in $aws_env
        string match -qr '^AWS[A-Z0-9_]*=' -- "$line"; or continue
        set -l key (string split -m1 '=' -- "$line")[1]
        set -l val (string split -m1 '=' -- "$line")[2]
        set -gx $key "$val"
    end

    set -gx AWS_PROFILE "$profile"
    set -gx AWS_DEFAULT_PROFILE "$profile"
    echo "Activated aws-vault profile: $profile"
end
