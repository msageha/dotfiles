#!/usr/bin/env bats

readonly SCRIPT_PATH="./docker/build.sh"

@test "[docker] build.sh --list prints every variant" {
    run "${SCRIPT_PATH}" --list
    [ "$status" -eq 0 ]
    [ "$(echo "$output" | tr '\n' ' ')" = "ubuntu-min ubuntu debian-min debian debian-slim-min alpine ubuntu-gpu " ]
}

@test "[docker] build.sh --list --multi-arch excludes the amd64-only GPU variant" {
    run "${SCRIPT_PATH}" --list --multi-arch
    [ "$status" -eq 0 ]
    [[ "$output" != *"ubuntu-gpu"* ]]
    [ "$(echo "$output" | wc -l | tr -d ' ')" -eq 6 ]
}

@test "[docker] build.sh rejects an unknown tag before touching docker" {
    run "${SCRIPT_PATH}" no-such-variant
    [ "$status" -eq 1 ]
    [[ "$output" == *"unknown tag: no-such-variant"* ]]
}

@test "[docker] build.sh requires a tag" {
    run "${SCRIPT_PATH}"
    [ "$status" -eq 1 ]
    [[ "$output" == *"usage:"* ]]
}

@test "[docker] CI workflows mirror the variants known to build.sh" {
    # docker-image-cd.yaml / docker.yaml の matrix は build.sh の表を写す (GitHub Actions は静的 matrix しか持てない)
    local tag
    for tag in $("${SCRIPT_PATH}" --list); do
        echo "Checking ${tag} in docker-image-cd.yaml"
        grep -q "tag: ${tag}$" .github/workflows/docker-image-cd.yaml
    done
    for tag in ubuntu-min debian-min alpine; do
        echo "Checking ${tag} in docker.yaml"
        grep -q "tag: ${tag}$" .github/workflows/docker.yaml
    done
}
