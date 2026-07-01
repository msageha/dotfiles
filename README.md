# dotfiles

macOS / Ubuntu 向けの dotfiles リポジトリ。[chezmoi](https://www.chezmoi.io/) で管理。

## Setup

### 事前準備 (Prerequisites)

セットアップには `curl` と `git` が必要。`curl` は chezmoi インストーラの取得に必須で、`git` はリポジトリの clone と `autoCommit` / `autoPush` の運用に使用する。

#### macOS

`curl` は標準搭載されている。`git` は Xcode Command Line Tools に含まれるため、未インストールの場合のみ以下を実行する（後続の Setup でも `xcode-select --install` は自動実行されるが、事前に入れておくと確実）。

```bash
xcode-select --install
```

#### Ubuntu

最小構成では `curl` / `git` ともに未インストールのことがあるため、先に導入する。

```bash
sudo apt update
sudo apt install -y curl git
```

### 実行

```bash
sh -c "$(curl -fsSL get.chezmoi.io)" -- -b "$HOME/.local/bin" init --apply --depth=1 https://github.com/msageha/dotfiles.git
```

### 初回セットアップ時に要求される項目

`chezmoi init --apply` の実行時に以下の項目が対話的に聞かれる（`~/.config/chezmoi/chezmoi.toml` に保存され、2 回目以降はスキップされる）。

#### 共通

| プロンプト            | データキー           | 説明                                                                                                                                         |
| --------------------- | -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| `Gemini API Key`      | `apiKeys.gemini`     | [Google AI Studio](https://aistudio.google.com/apikey) で発行。Gemini CLI 等で使用                                                           |
| `Google Maps API Key` | `apiKeys.googleMaps` | [Google Cloud Console](https://console.cloud.google.com/apis/credentials) で発行。Claude Code / Gemini CLI の maps-grounding-lite MCP に使用 |

#### macOS のみ

| プロンプト      | データキー      | 説明                                            |
| --------------- | --------------- | ----------------------------------------------- |
| `Computer name` | `computer_name` | macOS のコンピュータ名。空欄で `MacBook-<user>` |

#### Ubuntu のみ

| プロンプト                           | データキー     | 説明                                               |
| ------------------------------------ | -------------- | -------------------------------------------------- |
| `Skip apt package installation?`     | `skip_apt`     | `true` で apt パッケージのインストールをスキップ   |
| `Skip apt GUI package installation?` | `skip_apt_gui` | `true` で GUI 系パッケージのインストールをスキップ |

設定を変更したい場合は `chezmoi init` を再実行するか、`~/.config/chezmoi/chezmoi.toml` を直接編集する。

### Ubuntu VM

1. SSH 鍵をコピー

```bash
scp -r $HOME/.ssh/ <VM_HOST>:$HOME
```

2. セットアップ実行

```bash
sh -c "$(curl -fsSL get.chezmoi.io)" -- -b "$HOME/.local/bin" init --one-shot git@github.com:msageha/dotfiles.git
```

### Docker

```bash
make build_image
docker container run -it msageha/ubuntu:latest
```

GPU イメージのビルド:

```bash
make build_gpu_image
```

### 外付けキーボードのキーリマップ (macOS, 任意)

外付けキーボード向けのキーリマップは自動適用されない。必要な場合のみ手動で以下を実行する。

```bash
~/.local/share/chezmoi/install/macos/setup-external-keyboard.sh
```

`hidutil` でキーを再割り当てし、ログイン時に再適用する LaunchAgent (`~/Library/LaunchAgents/com.apple.KeyRemapping.plist`) を登録する。リマップ内容は次のとおり。

- Caps Lock → Control
- Option (Alt) → Command
- Command → Option

接続中のすべての HID キーボード (内蔵含む) に適用される点に注意。無効化する場合は次を実行する。

```bash
launchctl unload "$HOME/Library/LaunchAgents/com.apple.KeyRemapping.plist" && rm "$HOME/Library/LaunchAgents/com.apple.KeyRemapping.plist"
```

## Structure

```
.
├── home/                        # chezmoi 管理対象の dotfiles
│   ├── .chezmoi.toml.tmpl       # chezmoi 初期設定テンプレート
│   ├── .chezmoiscripts/         # chezmoi ライフサイクルスクリプト
│   ├── dot_alias.tmpl           # シェルエイリアス
│   ├── dot_bash_profile         # Bash 設定
│   ├── dot_zprofile             # Zsh 設定
│   ├── dot_gitconfig.tmpl       # Git 設定
│   ├── dot_tmux.conf            # Tmux 設定
│   ├── dot_vimrc                # Vim 設定
│   ├── dot_ssh/config           # SSH 設定
│   ├── dot_claude/              # Claude Code 設定
│   │   ├── CLAUDE.md            # グローバル指示ファイル
│   │   ├── settings.json.tmpl   # パーミッション・フック設定
│   │   └── skills/              # カスタムスキル (commit, gh-*, gws-*, pdf)
│   ├── dot_codex/               # OpenAI Codex 設定
│   ├── dot_gemini/              # Gemini CLI 設定
│   ├── modify_dot_claude.json.tmpl  # .claude.json の mcpServers を管理する modify スクリプト
│   └── dot_config/
│       ├── fish/                # Fish shell 設定 + カスタム関数
│       ├── ghostty/             # Ghostty ターミナル設定
│       ├── fastfetch/           # Fastfetch 設定
│       └── starship.toml        # Starship プロンプト設定
├── install/                     # インストールスクリプト
│   ├── common/                  # 共通 (mise, rust, fonts, fisher, etc.)
│   ├── macos/                   # macOS (brew, xcode, system settings)
│   └── ubuntu/                  # Ubuntu (apt, Docker)
├── tests/                       # BATS テスト
│   ├── files/                   # dotfile 存在チェック
│   └── install/                 # インストール検証
├── .github/workflows/           # CI/CD
│   ├── ci.yml                   # pre-commit, bats test, chezmoi dry-run/apply
│   └── claude.yaml              # Claude Code 連携
├── docker/                      # Docker イメージ定義
│   └── Dockerfile.debian        # Ubuntu 開発環境イメージ
├── Makefile                     # ビルド/テスト自動化
└── .pre-commit-config.yaml      # Lint/Format 設定
```

## Make Targets

| Target                 | Description                    |
| ---------------------- | ------------------------------ |
| `make test`            | BATS テスト実行                |
| `make pre-commit`      | Lint/Format チェック           |
| `make dry_run`         | chezmoi apply のドライラン     |
| `make apply`           | chezmoi apply 実行             |
| `make build_image`     | Docker イメージビルド          |
| `make build_gpu_image` | GPU 対応 Docker イメージビルド |
| `make push_image`      | Docker イメージ push           |
