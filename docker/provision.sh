#!/usr/bin/env bash
# Dockerfile.debian / Dockerfile.alpine の最終 RUN から実行する provisioning 本体。
# SKIP_CLI_TOOLS / SKIP_GUI_TOOLS は環境変数で受け取る。
set -euo pipefail

# secret は BuildKit 既定で root 所有 0400 のため、Dockerfile 側の mount で非 root ユーザーが
# 読めるよう mode=0444 を指定している (GitHub のレート制限回避用トークン。
# 未指定だと cat が権限拒否され匿名枠で 403 になる)。
# 汎用の GITHUB_TOKEN ではなく mise 専用変数で渡し、apply 中に実行される第三者の
# インストーラ (curl | sh) に gh のフルスコープ token を見せない
if [ -f /run/secrets/github_token ]; then
    MISE_GITHUB_TOKEN="$(cat /run/secrets/github_token)"
    export MISE_GITHUB_TOKEN
fi

sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" -t v2.72.2
export PATH="$HOME/.local/bin:$PATH"

mkdir -p "$HOME/.config/chezmoi"
printf '%s\n' \
    '[data]' \
    "skip_cli_tools = ${SKIP_CLI_TOOLS}" \
    "skip_gui_tools = ${SKIP_GUI_TOOLS}" \
    > "$HOME/.config/chezmoi/chezmoi.toml"
chezmoi apply --source="$HOME/dotfiles"

rm -rf "$HOME/dotfiles" "$HOME/.cache"
# java が導入されるビルド変種では src.zip を落とす
rm -f "$HOME/.local/share/mise/installs/java/"*/lib/src.zip
# chezmoi は provisioning 専用でランタイム不要。~42MB あるため apply 後に削除する
# (再適用が必要なら curl get.chezmoi.io で都度入れ直す)。
rm -f "$HOME/.local/bin/chezmoi"

# mise.run が入れるバイナリは strip されておらず ~83MB ある。binutils を一時導入して
# strip し (~70MB に縮む)、binutils はランタイムに残さず削除する。
if command -v apk >/dev/null 2>&1; then
    sudo apk add --no-cache --virtual .strip-deps binutils
    strip "$HOME/.local/bin/mise"
    sudo apk del .strip-deps
else
    sudo apt-get update
    sudo apt-get install -y --no-install-recommends binutils
    strip "$HOME/.local/bin/mise"
    sudo apt-get purge -y binutils
    sudo apt-get autoremove -y
    sudo apt-get clean
    sudo rm -rf /var/lib/apt/lists/*
fi
