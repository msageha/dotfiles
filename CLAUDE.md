@AGENTS.md

# Claude Code 固有の事項

- Claude Code の sandbox を有効にしているときは、read deny (`~/.ssh`・`/**/.env*`・`~/.codex/auth.json`・age 鍵の `~/.config/chezmoi/key.txt`) により、`.chezmoiignore` を通る chezmoi コマンド (`apply` / `diff` / `status` / `managed` / `unmanaged` / dry-run。`.chezmoiignore` が age 鍵を `stat` する。`~/.codex/.env`・`~/.gemini/.env` の lstat も通らない)、age 鍵を `stat` する template (`dot_config/git/config.tmpl` 等) の `chezmoi execute-template`、`mise run test` の `tests/files` (`common.bats` の `~/.ssh/config` と `coding_agents.bats` の `~/.codex/auth.json` の存在チェック、`fish.bats` の `chezmoi unmanaged`) が偽失敗する。
  キャッシュへの書き込みの偽失敗 (AGENTS.md「検証」) と同じく、コード起因と決めつけず、sandbox を外して再実行して切り分ける。
- このリポジトリの検証は mise タスクと prek の git hook (AGENTS.md「検証」) で完結しているため、Stop hook が実行する `.claude/verify.sh` は置かない。
  `.claude/` はローカル設定領域で、リポジトリの管理対象外 (`.gitignore` の whitelist に含めない)。
