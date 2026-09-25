#!/usr/bin/env bash
# Docker イメージのバリアント表とビルドの単一ソース。
#   docker/build.sh <tag> [--push]        : 1 バリアントをビルド (--push はマルチアーキで push)
#   docker/build.sh --list [--multi-arch] : タグ一覧 (--multi-arch は GPU を除く)
# GUI ツールはどのバリアントでもインストールしないため SKIP_GUI_TOOLS=true 固定。
set -euo pipefail

cd "$(dirname "$0")/.."

tags="ubuntu-min ubuntu debian-min debian debian-slim-min alpine ubuntu-gpu"

# 役割: -min=CLI ツールも省く最小構成 / 無印=CLI のみ (GUI 省略)
set_variant() {
    dockerfile=docker/Dockerfile.debian
    multi_arch=true
    case "$1" in
        ubuntu-min) base_image=ubuntu:26.04; skip_cli_tools=true ;;
        ubuntu) base_image=ubuntu:26.04; skip_cli_tools=false ;;
        debian-min) base_image=debian:trixie; skip_cli_tools=true ;;
        debian) base_image=debian:trixie; skip_cli_tools=false ;;
        debian-slim-min) base_image=debian:trixie-slim; skip_cli_tools=true ;;
        # Alpine は musl 環境のため最小構成 (skip_cli_tools=true) でビルドする。
        alpine) base_image=alpine:3.24; skip_cli_tools=true; dockerfile=docker/Dockerfile.alpine ;;
        # GPU は amd64 のみのためマルチアーキ対象外。
        ubuntu-gpu) base_image=nvidia/cuda:13.3.1-base-ubuntu26.04; skip_cli_tools=false; multi_arch=false ;;
        *)
            echo "unknown tag: $1 (available: $tags)" >&2
            exit 1
            ;;
    esac
}

if [ "${1:-}" = "--list" ]; then
    for tag in $tags; do
        set_variant "$tag"
        if [ "${2:-}" != "--multi-arch" ] || [ "$multi_arch" = true ]; then
            echo "$tag"
        fi
    done
    exit 0
fi

if [ $# -lt 1 ]; then
    echo "usage: $0 <tag> [--push] | $0 --list [--multi-arch]" >&2
    exit 1
fi

set_variant "$1"
image="${DOCKER_REPOSITORY:-msageha/dotfiles}:$1"

# GitHub のレート制限回避のため gh のトークンを BuildKit secret で渡す。
GITHUB_TOKEN="$(gh auth token -h github.com)"
export GITHUB_TOKEN

if [ "${2:-}" = "--push" ]; then
    if [ "$multi_arch" != true ]; then
        echo "$1 is amd64 only and cannot be built multi-arch" >&2
        exit 1
    fi
    # マルチアーキ manifest list はローカル docker に load できないため --push 一択
    # (事前に docker login 済みであること)。buildx ビルダー (mybuilder) は
    # mise run buildx-setup で有効化しておく。
    docker buildx build -f "$dockerfile" \
        --builder mybuilder \
        --secret id=github_token,env=GITHUB_TOKEN \
        --build-arg "BASE_IMAGE=$base_image" \
        --build-arg "SKIP_CLI_TOOLS=$skip_cli_tools" \
        --build-arg "SKIP_GUI_TOOLS=true" \
        --platform linux/amd64,linux/arm64 \
        --provenance=false \
        --push \
        -t "$image" .
else
    DOCKER_BUILDKIT=1 docker build \
        --secret id=github_token,env=GITHUB_TOKEN \
        -f "$dockerfile" \
        --build-arg "BASE_IMAGE=$base_image" \
        --build-arg "SKIP_CLI_TOOLS=$skip_cli_tools" \
        --build-arg "SKIP_GUI_TOOLS=true" \
        -t "$image" .
fi
