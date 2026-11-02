#!/usr/bin/env bash
# fixture/ から、履歴と bare の origin を持つ作業用リポジトリを <dest>/order-service に作る。
set -euo pipefail

src=$(cd "$(dirname "$0")/fixture" && pwd)
dest=$1
mkdir -p "$dest/order-service"
cp -R "$src/." "$dest/order-service/"
cd "$dest/order-service"
printf '%s\n' '__pycache__/' > .gitignore

git init -q --template= -b main
git config user.name 'Order Service Dev'
git config user.email 'dev@example.com'
git config commit.gpgsign false

commit() {
  local message=$1
  shift
  git add -- "$@"
  git commit -q -m "$message"
}
commit 'chore: プロジェクトの雛形を作る' .gitignore README.md Makefile app/__init__.py
commit 'feat(users): ユーザー一覧に pagination を入れる' app/pagination.py app/users.py tests/test_users.py
commit 'feat(orders): 注文一覧を追加する' app/orders.py
commit 'feat(config): 設定を config.toml から読む' config.toml app/config.py tests/test_config.py
commit 'feat(server): 一覧を返す HTTP サーバーを足す' app/server.py app/log.py
commit 'feat(taskgraph): タスクの依存順を求める' app/taskgraph.py
commit 'build: コンテナイメージを作る' docker/Dockerfile

git init -q --bare --template= "$dest/origin.git"
git remote add origin "$dest/origin.git"
git push -q -u origin main
