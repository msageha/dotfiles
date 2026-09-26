#!/usr/bin/env bats

# バリアント表 (tag / base image / skip_cli_tools / Dockerfile) は mise.toml の build-<tag> タスクが単一ソース。
variant_tags() {
    sed -nE 's/^run = "mise run docker-build ([a-z-]+) .*/\1/p' mise.toml
}

@test "[docker] mise.toml defines every variant task" {
    [ "$(variant_tags | tr '\n' ' ')" = "ubuntu-min ubuntu debian-min debian debian-slim-min alpine ubuntu-gpu " ]
}

@test "[docker] CI workflows mirror the variants known to mise.toml" {
    # docker-image-cd.yaml / docker.yaml の matrix は mise.toml の表を写す
    # (fromJSON で動的 matrix にもできるが、build-push-action の with: へ渡す値を静的に読めるよう写しにしている)
    local tag
    for tag in $(variant_tags); do
        echo "Checking ${tag} in docker-image-cd.yaml (build matrix and merge job)"
        grep -q "tag: ${tag}$" .github/workflows/docker-image-cd.yaml
        grep -qE "^\s+- ${tag}$" .github/workflows/docker-image-cd.yaml
    done
    for tag in ubuntu-min debian-min alpine; do
        echo "Checking ${tag} in docker.yaml"
        grep -q "tag: ${tag}$" .github/workflows/docker.yaml
    done
}
