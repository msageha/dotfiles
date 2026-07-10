function faws -d "Select and activate an AWS CLI profile"
    if not type -q aws
        echo "aws (AWS CLI) is required."
        return 1
    end
    if not type -q fzf
        echo "fzf is required."
        return 1
    end

    set -l profile (aws configure list-profiles | fzf --select-1 --prompt='aws> ')

    if test -z "$profile"
        return 1
    end

    # AWS_PROFILE より優先される静的クレデンシャルが残っていると
    # credential_process による解決を上書きしてしまうため消しておく
    set -e AWS_ACCESS_KEY_ID
    set -e AWS_SECRET_ACCESS_KEY
    set -e AWS_SESSION_TOKEN
    set -e AWS_SECURITY_TOKEN
    set -e AWS_CREDENTIAL_EXPIRATION
    set -e AWS_VAULT

    set -gx AWS_PROFILE "$profile"
    set -gx AWS_DEFAULT_PROFILE "$profile"
    echo "Activated AWS profile: $profile"
end
