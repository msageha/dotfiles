@AGENTS.md

# Claude Code 固有の事項

- Claude Code の sandbox を有効にしているときは、read deny (`~/.ssh`・`/**/.env*`) により `mise run test` (`tests/files/common.bats` の `~/.ssh/config` 存在チェック) や `chezmoi apply` / `diff` / dry-run (`~/.codex/.env` の lstat) が偽失敗する。
  write deny により `~/Library/Caches/mise|dprint` への書き込みも "Operation not permitted" になる。
  コード起因と決めつけず、sandbox を外して再実行して切り分ける。
- このリポジトリの検証は mise タスクと prek の git hook (AGENTS.md「検証」) で完結しているため、Stop hook が実行する `.claude/verify.sh` は置かない。
  `.claude/` はローカル設定領域で、リポジトリの管理対象外 (`.gitignore` の whitelist に含めない)。
