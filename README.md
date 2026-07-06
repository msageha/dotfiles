# dotfiles

macOS / Ubuntu / Debian / Windows 向けの dotfiles リポジトリ。[chezmoi](https://www.chezmoi.io/) で管理する。
機微な設定（一部の SSH ホスト定義・業務用 Git 設定・IME 辞書など）は
[age](https://age-encryption.org/) で暗号化してリポジトリに載せているため、公開しても安全な構成になっている。

`.chezmoiroot` = `home` のため、chezmoi の source root は `home/`。

## Setup

### 事前準備 (Prerequisites)

セットアップには `curl` と `git` が必要。`curl` は chezmoi インストーラの取得に必須で、`git` はリポジトリの clone と `autoCommit` / `autoPush` の運用に使用する。

#### macOS

`curl` は標準搭載されている。`git` は Xcode Command Line Tools に含まれるため、未インストールの場合のみ以下を実行する（後続の Setup でも `xcode-select --install` は自動実行されるが、事前に入れておくと確実）。

```bash
xcode-select --install
```

#### Ubuntu / Debian

最小構成では `curl` / `git` ともに未インストールのことがあるため、先に導入する。

```bash
sudo apt update
sudo apt install -y curl git
```

#### Windows

`git` が必要。Windows 向けスクリプトは既定搭載の Windows PowerShell 5.1 で動作するため、pwsh (PowerShell 7) の別途インストールは不要。`git` が無ければ winget で導入する。

```powershell
winget install --id Git.Git --exact --source winget
```

導入後は新しい PowerShell を開き直してから Setup に進む。

winget 自体は前提条件ではない。winget が無い環境 (Windows Server 2022 / Windows Sandbox など Microsoft Store 非搭載の環境) では、セットアップスクリプトが GitHub リリースの App Installer パッケージ (依存 + ライセンス XML 込み) から winget を自動導入する (`install/windows/winget.ps1`)。ただし Windows Server 2019 以前は winget 非対応。その場合や、上記の `git` 導入時点で winget が無い場合は、[Git for Windows](https://gitforwindows.org/) のインストーラーで `git` を導入する。

### 暗号化された設定の復号鍵 (age)

一部の設定ファイルは age で暗号化され、`encrypted_*.age` としてリポジトリに含まれている。

| 暗号化ファイル                                       | 展開先                           | 内容                                                             |
| ---------------------------------------------------- | -------------------------------- | ---------------------------------------------------------------- |
| `home/dot_ssh/encrypted_config.local.age`            | `~/.ssh/config.local`            | 非公開の SSH ホスト定義（`~/.ssh/config` から `Include` される） |
| `home/encrypted_dot_gitconfig.technoface.gitlab.age` | `~/.gitconfig.technoface.gitlab` | 業務用 Git 設定                                                  |
| `home/encrypted_dot_gitconfig.sakanaai.github.age`   | `~/.gitconfig.sakanaai.github`   | 業務用 Git 設定                                                  |
| `settings/common/encrypted_google.ime.txt.age`       | （手動インポート用）             | Google 日本語入力のユーザー辞書                                  |
| `settings/macos/btt/encrypted_licence.txt.age`       | （実行時に復号）                 | BetterTouchTool ライセンス                                       |

復号には age 秘密鍵が必要。**公開鍵 (recipient) は `home/.chezmoi.toml.tmpl` に記載してリポジトリに載せているが、秘密鍵はリポジトリに含めない。**

新しいマシンでこれらを展開するには、`chezmoi apply` の前に秘密鍵を配置する。

鍵を配置するマシン (新マシン) 側で実行:

```bash
mkdir -p ~/.config/chezmoi
# パスワードマネージャ等から取得する例:
# op document get "chezmoi age key" --out-file ~/.config/chezmoi/key.txt
chmod 600 ~/.config/chezmoi/key.txt
```

鍵を持つ既存マシンから scp で転送する場合は、既存マシン側で実行:

```bash
ssh <NEW_HOST> 'mkdir -p ~/.config/chezmoi'
scp ~/.config/chezmoi/key.txt <NEW_HOST>:~/.config/chezmoi/key.txt
ssh <NEW_HOST> 'chmod 600 ~/.config/chezmoi/key.txt'
```

秘密鍵が無い環境（コンテナ・鍵未配置の初回など）でも `chezmoi apply` は失敗しない。`.chezmoiignore` が鍵の有無を判定し、復号できない暗号化ファイルを自動でスキップする（該当設定が展開されないだけ）。

### 実行

公開リポジトリなので HTTPS なら認証不要でどのマシンからでも clone できる。初回セットアップにはこちらを推奨。

```bash
sh -c "$(curl -fsSL get.chezmoi.io)" -- -b "$HOME/.local/bin" init --apply --depth=1 https://github.com/msageha/dotfiles.git
```

Windows (Windows PowerShell 5.1) の場合:

```powershell
iex "&{$(irm 'https://get.chezmoi.io/ps1')} -b '$HOME\.local\bin'"
$env:Path = "$HOME\.local\bin;$env:Path"
chezmoi init --apply --depth=1 https://github.com/msageha/dotfiles.git
```

chezmoi が実行するセットアップスクリプトは `-ExecutionPolicy Bypass` 付きで起動されるため、実行ポリシーが既定の `Restricted` のままでも動作する。`install/windows/*.ps1` を手動で実行したい場合のみ `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` が必要になることがある。

SSH URL (`git@github.com:msageha/dotfiles.git`) も利用できるが、その場合はそのマシンに GitHub 登録済みの SSH 鍵が既に必要（未設定の初回マシンでは clone に失敗する）。`autoCommit` / `autoPush` で push し返すオーナー環境では、鍵を配置してから remote を SSH に切り替えると push が楽になる。

```bash
git -C ~/.local/share/chezmoi remote set-url origin git@github.com:msageha/dotfiles.git
```

#### 一度きりの適用（痕跡を残さない / one-shot）

コンテナや他人のマシンなど、chezmoi の source (`~/.local/share/chezmoi`) や設定を残したくない環境では `--one-shot` を使う。適用後に source ディレクトリ・設定 (`~/.config/chezmoi`)・インストールした chezmoi バイナリまで自動で削除する（実質 `--apply --depth 1 --force --purge --purge-binary` 相当）。

```bash
sh -c "$(curl -fsSL get.chezmoi.io)" -- init --one-shot https://github.com/msageha/dotfiles.git
```

注意点:

- `--one-shot` は `--force` を含むため、通常は対話的に聞かれる項目（`computer_name` など）が確認されずデフォルト値で進む。値を指定したい場合はこの方式ではなく通常の `init --apply` を使う。
- 暗号化ファイルを展開したい場合は、one-shot でも事前に age 秘密鍵の配置が必要（未配置なら該当ファイルは自動スキップされる）。

### 初回セットアップ時に要求される項目

`chezmoi init --apply` の実行時に以下が対話的に聞かれる（`~/.config/chezmoi/chezmoi.toml` に保存され、2 回目以降はスキップされる）。設定を変更したい場合は `chezmoi init` を再実行するか、`~/.config/chezmoi/chezmoi.toml` を直接編集する。

#### macOS のみ

| プロンプト      | データキー      | 説明                   |
| --------------- | --------------- | ---------------------- |
| `computer_name` | `computer_name` | macOS のコンピュータ名 |

#### Linux (Ubuntu / Debian) のみ

| プロンプト                        | データキー       | 説明                                                                                                                              |
| --------------------------------- | ---------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| `Skip CLI tool installation ...?` | `skip_cli_tools` | CLI ツール（各種ユーティリティ・chezmoi・docker・gh 等）とコーディングエージェント設定をスキップするかどうか（デフォルト `true`） |
| `Skip GUI tool installation?`     | `skip_gui_tools` | GUI 系パッケージのインストールをスキップするかどうか（デフォルト `true`）                                                         |

#### Windows のみ

| プロンプト                                              | データキー            | 説明                                                                                                                                                                                                                       |
| ------------------------------------------------------- | --------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Skip coding agent / GUI apps / system settings setup?` | `skip_windows_extras` | コーディングエージェント CLI・GUI アプリ (Chrome 等)・システム設定 (エクスプローラー/壁紙/タスクバー等) をまとめてスキップするかどうか（デフォルト `true`）。`false` にするとコーディングエージェントの API キーも聞かれる |

#### API キー

以下はコーディングエージェント設定を管理する環境（macOS、Linux で `skip_cli_tools=false`、または Windows で `skip_windows_extras=false`）でのみ聞かれる。
空欄でも可（未設定として展開される）。

| プロンプト              | データキー           | 説明                                                                                                             |
| ----------------------- | -------------------- | ---------------------------------------------------------------------------------------------------------------- |
| `Gemini API Key`        | `apiKeys.gemini`     | [Google AI Studio](https://aistudio.google.com/apikey) で発行。Gemini CLI / nano-banana MCP 等で使用             |
| `Google Maps API Key`   | `apiKeys.googleMaps` | [Google Cloud Console](https://console.cloud.google.com/apis/credentials) で発行。maps-grounding-lite MCP で使用 |
| `Fugu (Sakana) API Key` | `apiKeys.fugu`       | Codex の Sakana プロバイダで使用                                                                                 |
| `OpenRouter API Key`    | `apiKeys.openRouter` | Codex / Claude Code の OpenRouter プロバイダで使用                                                               |

API キーはローカルの `~/.config/chezmoi/chezmoi.toml` にのみ保存され、リポジトリには入らない（テンプレートは `dig` で参照し、未設定時は空文字で展開される）。

### Docker

開発環境イメージをローカルでビルドできる（ベース OS / ツール構成別の 7 バリアント）。イメージ名は既定で `msageha/dotfiles:<tag>`（`DOCKER_REPOSITORY` で上書き可）。

```bash
make build-ubuntu                    # 標準構成 (Ubuntu + CLI)
docker container run -it msageha/dotfiles:ubuntu
```

| ターゲット                   | タグ              | 構成                             |
| ---------------------------- | ----------------- | -------------------------------- |
| `make build-ubuntu-min`      | `ubuntu-min`      | Ubuntu / 最小 (CLI ツールも省く) |
| `make build-ubuntu`          | `ubuntu`          | Ubuntu / CLI                     |
| `make build-debian-min`      | `debian-min`      | Debian / 最小                    |
| `make build-debian`          | `debian`          | Debian / CLI                     |
| `make build-debian-slim-min` | `debian-slim-min` | Debian slim / 最小               |
| `make build-alpine`          | `alpine`          | Alpine / 最小                    |
| `make build-ubuntu-gpu`      | `ubuntu-gpu`      | Ubuntu + CUDA + CLI (amd64 のみ) |

マルチアーキ (amd64/arm64) ビルドと registry への push は `make build-multi-platform` / `make push`。CI では `cloudbuild.yaml` が Artifact Registry へ push する。

ビルドコンテキストには機微な平文（例: 復号した IME 辞書）が入らないよう `.dockerignore` で除外している。暗号化済み `*.age` は ciphertext のため同梱されても安全。

### 外付けキーボードのキーリマップ (macOS, 任意)

設定から、変更するキーの組み合わせを以下のように入れ替える。

- Caps Lock → Control
- Option (Alt) → Command
- Command → Option

## 暗号化された設定の編集

age 秘密鍵を配置済みの環境で、暗号化ファイルを編集・再暗号化する。

`home/` 配下（chezmoi 管理対象）のファイルは chezmoi が透過的に復号/再暗号化する。

```bash
chezmoi edit ~/.ssh/config.local      # 復号して編集 → 保存時に再暗号化
chezmoi decrypt <source>/encrypted_foo.age   # 標準出力へ復号
```

`settings/` 配下（chezmoi 管理外）は Make ターゲットを使う。

```bash
make decrypt_google_ime   # encrypted_google.ime.txt.age → settings/common/google.ime.txt (平文, gitignore 済み)
make encrypt_google_ime   # 平文を編集後に再暗号化
```

## Structure

```
.
├── home/                          # chezmoi 管理対象の dotfiles (source root)
│   ├── .chezmoi.toml.tmpl         # 初期設定テンプレート (プロンプト・age recipient)
│   ├── .chezmoiignore             # 鍵の有無で暗号化ファイルの適用を制御
│   ├── .chezmoiscripts/           # chezmoi ライフサイクルスクリプト
│   ├── dot_alias.tmpl             # シェルエイリアス
│   ├── dot_gitconfig.tmpl         # Git 設定 (業務用は暗号化した include を条件付きで参照)
│   ├── dot_gitconfig.github       # 個人 GitHub 用 Git 設定
│   ├── dot_ssh/
│   │   ├── config.tmpl            # 公開可の SSH 設定 (~/.ssh/config.local を Include)
│   │   └── encrypted_config.local.age   # 非公開ホスト定義 (age 暗号化)
│   ├── encrypted_dot_gitconfig.*.age    # 業務用 Git 設定 (age 暗号化)
│   ├── dot_claude/                # Claude Code 設定 (CLAUDE.md, settings, skills, rules)
│   ├── dot_codex/                 # OpenAI Codex 設定
│   ├── dot_gemini/                # Gemini CLI 設定
│   ├── modify_private_dot_claude.json   # ~/.claude.json を管理 (マシンローカル状態のみ温存)
│   └── dot_config/                # fish / ghostty / mise / starship 等
├── install/                       # インストールスクリプト
│   ├── common/                    # 共通 (mise, fonts, fisher, age 等)
│   ├── macos/                     # macOS (brew, xcode, system/app settings)
│   ├── debian/ ubuntu/ alpine/    # Linux 系
│   └── windows/                   # Windows (winget ブートストラップ・コーディングエージェント・GUI アプリ・Starship 等・システム設定、.chezmoiscripts から実行)
├── settings/                      # アプリ設定 (chezmoi 管理外, スクリプトが参照)
│   ├── common/                    # ghostty / vscode / IME 辞書(暗号化)
│   └── macos/                     # Raycast / BetterTouchTool(preset・ライセンス暗号化)
├── tests/                         # BATS テスト (files / install)
├── docker/                        # イメージ定義 (Dockerfile.debian / Dockerfile.alpine)
├── .github/workflows/             # CI (prek, bats, chezmoi dry-run) / Claude 連携
├── cloudbuild.yaml                # Cloud Build (マルチアーキ build & push)
├── Makefile                       # ビルド / テスト / 暗号化ユーティリティ
├── .pre-commit-config.yaml        # Lint/Format 設定 (prek で実行)
└── _typos.toml                    # typos 設定 (*.age を除外)
```
