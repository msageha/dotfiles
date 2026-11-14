# dotfiles

macOS / Ubuntu / Debian / Windows の開発環境を [chezmoi](https://www.chezmoi.io/) で再現する dotfiles。

- シェル: bash / zsh / fish / PowerShell の設定と Starship のプロンプト
- ターミナル: Ghostty・tmux・Windows Terminal の設定 (配色は Dracula)
- ツール: Homebrew / apt / winget / mise による CLI・GUI アプリの導入と設定
- コーディングエージェント: Claude Code / Codex / Antigravity / Grok の設定・skill・サブエージェント
- OS のシステム設定

公開リポジトリなので、非公開の設定 (SSH ホスト定義・業務用 Git 設定・IME 辞書など) は [age](https://age-encryption.org/) で暗号化して置き、age 秘密鍵・SSH 秘密鍵・API キーは 1Password から取得する。

## Setup

### 1. 事前準備

`curl` と `git` を入れる。

```sh
# macOS の場合 (表示されるダイアログから Command Line Tools を入れる)
xcode-select --install
# macOS でダイアログが出ないとき (SSH 越し等)。<Label> は --list が表示する Command Line Tools の Label
softwareupdate --list
sudo softwareupdate --install "<Label>"

# Ubuntu / Debian の場合
sudo apt update && sudo apt install -y curl git

# Windows の場合 (実行後に PowerShell を開き直す)
winget install --id Git.Git --exact --source winget
```

winget が無い Windows (Windows Server・Windows Sandbox 等) では、[Git for Windows](https://gitforwindows.org/) を入れる。

### 2. 適用

```sh
# macOS / Linux の場合
sh -c "$(curl -fsSL get.chezmoi.io)" -- -b "$HOME/.local/bin" init --apply --depth=1 https://github.com/msageha/dotfiles.git && bash ~/.local/share/chezmoi/install/common/secrets.sh

# Windows の場合 (標準の Windows PowerShell 5.1 で動く)
iex "&{$(irm 'https://get.chezmoi.io/ps1')} -b '$HOME\.local\bin'"
$env:Path = "$HOME\.local\bin;$env:Path"
[Environment]::SetEnvironmentVariable('Path', "$HOME\.local\bin;" + [Environment]::GetEnvironmentVariable('Path', 'User'), 'User')
chezmoi init --apply --depth=1 https://github.com/msageha/dotfiles.git
```

macOS / Linux で `skip_secrets=false` を選ぶときは、先に SSH 秘密鍵を 1Password に取り込んでおく ([SSH 秘密鍵](#ssh-秘密鍵))。

OS の設定も書き換わる。
macOS では Dock のアプリを決まったものだけに並べ直し、Finder やキーボード等の設定を変える。
Windows (`skip_windows_extras=false`) では OneDrive をアンインストールし、システムドライブで BitLocker が有効なら全ドライブの BitLocker を無効にする。

初回は次の項目を聞かれる (macOS ではほかにコンピュータ名も聞かれる)。
既定はどれも `true` (最小構成) なので、手元の開発マシンでは `false` を選ぶ。
答えは `~/.config/chezmoi/chezmoi.toml` に保存される。変えるときはこのファイルを編集して `chezmoi apply` する。

| 項目                  | 対象 OS       | `true` のときに省くもの                                                                                 |
| --------------------- | ------------- | ------------------------------------------------------------------------------------------------------- |
| `skip_cli_tools`      | macOS / Linux | CLI ツール (docker・gh・言語ランタイム等) とコーディングエージェント (本体と設定)                       |
| `skip_gui_tools`      | macOS / Linux | GUI アプリ・フォント・アプリ設定・Ubuntu のシステム設定 (`skip_cli_tools=true` なら常に `true`)         |
| `skip_secrets`        | macOS / Linux | 1Password からの age 秘密鍵・API キー・SSH 秘密鍵の取得 (`skip_cli_tools=true` なら常に `true`)         |
| `skip_windows_extras` | Windows       | コーディングエージェント (本体と設定)・GUI アプリ・システム設定 (mise とシェル補完は値によらず入らない) |

`skip_secrets` を後から `false` にしたときは、次で secret を取得する。

```sh
bash ~/.local/share/chezmoi/install/common/secrets.sh
```

Windows と `skip_cli_tools=true` の macOS / Linux では、[secret を手で取得する](#secret-を手で取得する) の手順で取得する。

適用が終わったら、新しいシェルを開く。
Windows では、配置した PowerShell プロファイルを読み込めるよう、一度だけ次を実行する (GPO で実行ポリシーが強制されている環境では変えられない)。

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

使い捨てのコンテナなどでは `init --one-shot` を使う。
質問をせずに既定値で適用し、既存のファイルを確認なしに上書きしてから、source・chezmoi の設定・chezmoi 本体を削除する。

```sh
sh -c "$(curl -fsSL get.chezmoi.io)" -- -b "$HOME/.local/bin" init --one-shot https://github.com/msageha/dotfiles.git
```

### 3. 手動で行う設定

- macOS の外付けキーボード: システム設定で Caps Lock → Control、Option → Command、Command → Option に入れ替える。
- Google 日本語入力: 次で復号した `settings/common/google.ime.txt` を、辞書ツールからインポートする。

  ```sh
  mise -C ~/.local/share/chezmoi run decrypt-google-ime
  ```

- VS Code: Custom CSS の拡張機能から `settings/common/vscode/styles.css` を読み込む。
- BetterTouchTool / Raycast / Stream Deck (macOS): 適用時に開く各アプリのダイアログで、設定を取り込む。
  初回の適用中に出る System Events の操作の許可も許可する (BetterTouchTool をログイン項目に登録するのに使う)。
- 変更を push するマシン: SSH 秘密鍵を置いた後に、remote を SSH に切り替える。

  ```sh
  git -C ~/.local/share/chezmoi remote set-url origin git@github.com:msageha/dotfiles.git
  ```

## 日常の操作

```sh
chezmoi update  # リポジトリの変更を pull して適用する
chezmoi apply   # ~/.local/share/chezmoi の変更を適用する
```

設定は `home/` 以下の source を編集する (適用先を直接編集しても、次の apply で上書きされる)。
`chezmoi edit` / `chezmoi add` は、commit と push まで自動で行う。
暗号化したファイルは、age 秘密鍵がある環境で `chezmoi edit` で編集する。
IME 辞書は、平文に戻して編集してから暗号化し直す (平文は git に入らない)。

```sh
cd ~/.local/share/chezmoi
mise run decrypt-google-ime
mise run encrypt-google-ime
```

## secret の扱い

### API キー

API キーは `fnox.toml` に暗号化して置き、`chezmoi.toml` と、キーを使う各ツールの設定ファイルに展開する。
空のキーを使う設定は認証なしで展開する (`~/.netrc` は、キーが空なら既存のファイルを残す)。

| 環境変数               | 用途                                                                                                |
| ---------------------- | --------------------------------------------------------------------------------------------------- |
| `GEMINI_API_KEY`       | Antigravity CLI・nano-banana MCP ([Google AI Studio](https://aistudio.google.com/apikey))           |
| `GOOGLE_MAP_API_KEY`   | maps-grounding-lite MCP ([Google Cloud Console](https://console.cloud.google.com/apis/credentials)) |
| `FUGU_API_KEY`         | Codex の Sakana プロバイダ                                                                          |
| `FUGU_PAYG_API_KEY`    | Codex の `fugu-cyber` プロファイル (Sakana PAYG プロバイダ)                                         |
| `SONATYPE_GUIDE_TOKEN` | Claude Code の sonatype-guide plugin                                                                |
| `TAKUMI_GUARD_API_KEY` | Takumi Guard (下記) の token。空なら匿名で使う                                                      |

macOS / Linux では、パッケージを悪性パッケージを遮断する [Takumi Guard](https://shisho.dev/docs/ja/t/guard/quickstart/npm/) 経由で取得する。
Go (`GOPROXY`) はどの構成でも、npm / pip / uv は `skip_cli_tools=false` のときだけ設定する。
Go は Takumi Guard から取得できないものを直接取りに行かないので、private module は `GOPRIVATE` に入れる。

### SSH 秘密鍵

`~/.ssh` の鍵は、1Password から取得してファイルとして置く (1Password の SSH agent を使えない環境でも使うため)。
Windows には置かない (chezmoi が NTFS の権限を絞れないため)。
置く鍵は `home/.chezmoidata.toml` の `[ssh_keys]` で決まる。
各鍵は 1Password アプリで、`vault` の vault に `item` の名前の SSH Key item として取り込んでおく (passphrase は外れる)。

鍵は `secrets.sh` か次のタスクでだけ置かれる。1Password 側で鍵を変えたときも、これを実行し直す。

```sh
mise -C ~/.local/share/chezmoi run apply-ssh-keys
```

chezmoi が管理していない別内容の鍵が既にあると、何も表示せずに exit 1 で止まる。
対象を確かめ、上書きしてよければ `--force` を付ける。

```sh
chezmoi status --override-data '{"apply_ssh_keys": true}' ~/.ssh
mise -C ~/.local/share/chezmoi run apply-ssh-keys -- --force
```

`apply_ssh_keys` は `chezmoi.toml` に書かない (通常の操作でも 1Password を呼ぶようになる)。
これを付けた `chezmoi diff` / `chezmoi apply --verbose` は、秘密鍵を平文で表示する。

### secret を手で取得する

`secrets.sh` を使えない Windows と `skip_cli_tools=true` の macOS / Linux では、次を 1 つのシェルで順に実行する (サインインの session token は環境変数で渡るため)。
Windows ではこのリポジトリが 1Password CLI (`op`) と `fnox` を入れないので、先に入れておく。

```sh
# op が無い macOS / Linux の場合 (以降もこのディレクトリで実行する)
cd ~/.local/share/chezmoi && mise trust && mise install

# CLI にアカウントを登録していなければ、op signin の代わりに op account add --signin を使う
eval "$(op signin)"               # bash / zsh / fish
Invoke-Expression "$(op signin)"  # PowerShell

# PowerShell では mkdir -p の代わりに New-Item -ItemType Directory -Force
mkdir -p ~/.config/chezmoi
op read --out-file ~/.config/chezmoi/key.txt --file-mode 0600 'op://Private/age-identity/password'
chezmoi apply

# Windows (skip_windows_extras=false) の場合、API キーを入れる
fnox --config "$HOME/.local/share/chezmoi/fnox.toml" exec -- chezmoi apply --init

# macOS / Linux の場合、SSH 秘密鍵を置く
mise -C ~/.local/share/chezmoi run apply-ssh-keys
```

## Docker

この dotfiles を適用したイメージを、リポジトリのディレクトリでビルドできる (Docker と、ログイン済みの `gh` が要る)。

```sh
mise run build-ubuntu
docker container run -it msageha/dotfiles:ubuntu
```

| タスク                           | 構成                                        |
| -------------------------------- | ------------------------------------------- |
| `mise run build-ubuntu-min`      | Ubuntu / 最小 (CLI ツールも省く)            |
| `mise run build-ubuntu`          | Ubuntu / CLI ツール入り                     |
| `mise run build-debian-min`      | Debian / 最小                               |
| `mise run build-debian`          | Debian / CLI ツール入り                     |
| `mise run build-debian-slim-min` | Debian slim / 最小                          |
| `mise run build-alpine`          | Alpine / 最小                               |
| `mise run build-ubuntu-gpu`      | Ubuntu + CUDA / CLI ツール入り (amd64 のみ) |

amd64 / arm64 のイメージを registry へ push するときは、次を実行する。
GPU のイメージは対象外で、イメージ名は `DOCKER_REPOSITORY` で変えられる (既定は `msageha/dotfiles`)。

```sh
docker login
mise run buildx-setup
mise run build-<tag> --push    # 1 つのバリアント
mise run build-multi-platform  # 全バリアント
```

## 開発

```sh
mise trust
mise install         # 開発ツールの導入と git hook の登録
mise run pre-commit  # lint / format
mise run pre-push    # 全テンプレートの描画と、apply に依存しないテスト
mise run test        # 全テスト (適用後の $HOME の検査を含む)
```

LLM エージェントの指示文を編集するときは、先に `docs/agent-instructions.md` を読む。
AI coding agent から起動されたシェルでは、editor・pager・対話 prompt を止める (`docs/agent-shell.md`)。

## Structure

```
.
├── home/                  # chezmoi の source root (.chezmoiroot)
│   ├── .chezmoi.toml.tmpl # 初回の質問と age の公開鍵
│   ├── .chezmoidata.toml  # テンプレートが共有するデータ (SSH 鍵の一覧・MCP の版等)
│   ├── .chezmoiignore     # OS・skip_*・age 秘密鍵の有無で適用対象を絞る
│   ├── .chezmoiscripts/   # 適用時に走るスクリプト (install/ を include する)
│   └── modify_*           # 既存ファイルの一部だけを管理する
├── install/               # OS 別のインストールスクリプト
├── settings/              # chezmoi が配置しないアプリ設定 (IME 辞書・Raycast・BetterTouchTool 等)
├── docker/                # Docker イメージの定義
├── docs/                  # Agent が使うシェルと、LLM エージェント指示文の配り方
└── AGENTS.md / CLAUDE.md  # このリポジトリで作業する LLM エージェント向けの規約
```
