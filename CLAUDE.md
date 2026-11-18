@AGENTS.md

# Claude Code 固有の事項

- Claude Code の sandbox を有効にしているときは、read deny (`~/.ssh`・`/**/.env*`・age 鍵の `~/.config/chezmoi/key.txt`) により `mise run test` (`tests/files/common.bats` の `~/.ssh/config` 存在チェック)、`chezmoi apply` / `diff` / `status` / dry-run (`~/.codex/.env`・`~/.gemini/.env` の lstat)、age 鍵を `stat` する template (`dot_config/git/config.tmpl` 等) の `chezmoi execute-template` が偽失敗する。
  mise・dprint 等のキャッシュ (`~/Library/Caches/`) への書き込みも "Operation not permitted" で落ちる。
  コード起因と決めつけず、sandbox を外して再実行して切り分ける。
- このリポジトリの検証は mise タスクと prek の git hook (AGENTS.md「検証」) で完結しているため、Stop hook が実行する `.claude/verify.sh` は置かない。
  `.claude/` はローカル設定領域で、リポジトリの管理対象外 (`.gitignore` の whitelist に含めない)。
