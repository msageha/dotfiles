# dotfiles

macOS / Ubuntu / Debian / Windows の開発環境を [chezmoi](https://www.chezmoi.io/) で再現する dotfiles。

- シェル: bash / zsh / fish / PowerShell の設定と Starship のプロンプト
- ターミナル: Ghostty・tmux・Windows Terminal の設定 (配色は Dracula で統一)
- ツール: Homebrew / apt / winget / mise による CLI・GUI アプリの導入と、git・ripgrep 等の設定
- コーディングエージェント: Claude Code / Codex / Antigravity / Grok の設定・skill・サブエージェント
- OS: macOS・Ubuntu・Windows のシステム設定

公開リポジトリなので、機微な設定 (非公開の SSH ホスト定義・業務用 Git 設定・IME 辞書など) は [age](https://age-encryption.org/) で暗号化して置き、SSH 秘密鍵と API キーは 1Password から取得する。

## Setup

### 1. 事前準備

`curl` と `git` を入れる。

- macOS: `xcode-select --install` を実行し、表示されるダイアログから Command Line Tools をインストールする。
  ダイアログが出ないとき (SSH 越し等) は、`softwareupdate --list` が表示する `Command Line Tools for Xcode` の `Label` の値を `sudo softwareupdate --install "<Label>"` に渡す。
  `xcode-select -p` が `/Library/Developer/CommandLineTools` を返せば完了。
- Ubuntu / Debian: `sudo apt update && sudo apt install -y curl git`
- Windows: `winget install --id Git.Git --exact --source winget` を実行し、PowerShell を開き直す。
  winget が無い環境 (Windows Server・Windows Sandbox 等) では [Git for Windows](https://gitforwindows.org/) を使う。
  標準の Windows PowerShell 5.1 で動くので、PowerShell 7 は要らない。

### 2. 適用

適用すると OS の設定も変わる。

- macOS: Dock のアプリを全て外して決まったアプリだけを並べ直し、Finder・キーボード等の設定を `defaults` で書き換える。
- Windows (`skip_windows_extras=false`): OneDrive をアンインストールし、システムドライブで BitLocker が有効なら、全ドライブの BitLocker を無効にする (復号が始まる)。

macOS / Linux:

```bash
sh -c "$(curl -fsSL get.chezmoi.io)" -- -b "$HOME/.local/bin" init --apply --depth=1 https://github.com/msageha/dotfiles.git
```

Windows (PowerShell 5.1):

```powershell
iex "&{$(irm 'https://get.chezmoi.io/ps1')} -b '$HOME\.local\bin'"
$env:Path = "$HOME\.local\bin;$env:Path"
[Environment]::SetEnvironmentVariable('Path', "$HOME\.local\bin;" + [Environment]::GetEnvironmentVariable('Path', 'User'), 'User')
chezmoi init --apply --depth=1 https://github.com/msageha/dotfiles.git
```

初回は次の項目を聞かれる。
`skip_*` の既定はどれも `true` (最小構成) なので、手元の開発マシンでは `false` を選ぶ。
答えは `~/.config/chezmoi/chezmoi.toml` に保存され、`chezmoi init` を再実行しても聞き直さない (変えるときはこのファイルを編集して `chezmoi apply` する)。

| データキー            | 対象 OS       | `true` のときに入れないもの                                                                                        |
| --------------------- | ------------- | ------------------------------------------------------------------------------------------------------------------ |
| `skip_cli_tools`      | macOS / Linux | CLI ツール (docker・gh・言語ランタイム等) とコーディングエージェント設定                                           |
| `skip_gui_tools`      | macOS / Linux | GUI アプリ・フォント・アプリ設定・Ubuntu のシステム設定 (`skip_cli_tools=true` なら `true` に固定)                 |
| `skip_windows_extras` | Windows       | コーディングエージェント・GUI アプリ・システム設定 (`false` でも `install/common/` の mise やシェル補完は入らない) |

macOS では、ほかにコンピュータ名 (`computer_name`) を聞かれる。

適用が終わったら、新しいシェルを開く (導入したツールに PATH が通る)。
Windows では、配置した PowerShell プロファイルを読み込めるよう、一度だけ次を実行する (既定の `Restricted` のままでは、起動のたびに `PSSecurityException` になる)。
`Get-ExecutionPolicy -List` の `MachinePolicy` / `UserPolicy` に値があれば GPO で強制されていて、これでは変えられない。

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

使い捨てのコンテナなどでは、`init --apply --depth=1` の代わりに `init --one-shot` を使う。
上の質問をせず既定値で適用し、既存のファイルを確認なしに上書きしたうえで、source・chezmoi の設定・chezmoi 本体を削除する (適用した設定と導入したツールは残る)。

### 3. secret の展開

初回の適用では age 秘密鍵が無いので、暗号化したファイルは飛ばされ、API キーは空で展開され、SSH 秘密鍵は置かれない (適用は失敗しない)。
1Password CLI (`op`) を使って次の順に展開する。
手でサインインしたときの session token は環境変数で渡るので、一連のコマンドは 1 つのシェルで実行する。
対象のファイルと鍵の詳細は [secret の扱い](#secret-の扱い) にある。

1. `op` にサインインする。1Password アプリの CLI 連携 (設定 > 開発者) を有効にしていれば要らない。
   `op` が無い macOS / Linux (Linux や、GUI アプリを入れない macOS) では、`cd ~/.local/share/chezmoi && mise trust && mise install` で入れ、以降をこのディレクトリで実行する。
   Windows ではこのリポジトリが `op` と `fnox` を入れないので、別に導入する。

   ```sh
   eval "$(op signin)"               # bash / zsh / fish
   Invoke-Expression "$(op signin)"  # PowerShell
   ```

2. age 秘密鍵を置いて再適用し、暗号化したファイルを展開する。
   PowerShell では、`mkdir -p` の代わりに `New-Item -ItemType Directory -Force ~/.config/chezmoi` を使う。

   ```bash
   mkdir -p ~/.config/chezmoi
   op read --out-file ~/.config/chezmoi/key.txt --file-mode 0600 'op://Private/age-identity/password'
   chezmoi apply
   ```

3. コーディングエージェント設定を入れる環境 (`skip_cli_tools=false`、Windows は `skip_windows_extras=false`) では、API キーを入れる。
   `fnox` が `fnox.toml` の API キーを復号して環境変数に入れ、`--init` がそれを `chezmoi.toml` の `data.apiKeys` に書き込むので、以降は secret を変えない限り `chezmoi apply` だけでよい。

   ```bash
   fnox --config "$HOME/.local/share/chezmoi/fnox.toml" exec -- chezmoi apply --init
   ```

4. macOS / Linux では、SSH 秘密鍵を置く。鍵は先に 1Password に取り込んでおく ([SSH 秘密鍵](#ssh-秘密鍵))。

   ```bash
   mise -C ~/.local/share/chezmoi run apply-ssh-keys
   ```

5. 変更を push するマシンでは、remote を SSH に切り替える。

   ```bash
   git -C ~/.local/share/chezmoi remote set-url origin git@github.com:msageha/dotfiles.git
   ```

### 4. 手動で行う設定

- Google 日本語入力: `mise -C ~/.local/share/chezmoi run decrypt-google-ime` で復号した `settings/common/google.ime.txt` を辞書ツールからインポートする。
- VS Code: Custom CSS の拡張機能から `settings/common/vscode/styles.css` を読み込む。
- BetterTouchTool / Raycast / Stream Deck (macOS): 適用時に設定ファイルを開くので、各アプリのダイアログで取り込む。
  BetterTouchTool をログイン項目に登録するため、初回の適用中にターミナルへ System Events の操作の許可を求めるダイアログが出るので許可する (拒否するとシステム設定 > 一般 > ログイン項目 での追加を促す警告が出る)。

## 日常の操作

```bash
chezmoi update   # リポジトリの変更を pull して適用する
chezmoi apply    # source (~/.local/share/chezmoi) の変更を適用する
```

設定は `home/` の source を編集する。適用先を直接編集しても、次の apply で上書きされる。
`chezmoi edit` / `chezmoi add` は commit と push まで自動で行う (`autoCommit` / `autoPush`)。

暗号化したファイルは、age 秘密鍵がある環境で編集する。

```bash
chezmoi edit ~/.ssh/config.local   # 復号して編集し、保存時に再暗号化する
cd ~/.local/share/chezmoi
mise run decrypt-google-ime        # settings/ の IME 辞書を平文に戻す (平文は gitignore 済み)
mise run encrypt-google-ime        # 編集した平文を再暗号化する
```

## secret の扱い

### 暗号化したファイル

| ファイル                                                     | 展開先                                   | 内容                                                        |
| ------------------------------------------------------------ | ---------------------------------------- | ----------------------------------------------------------- |
| `home/private_dot_ssh/encrypted_config.local.age`            | `~/.ssh/config.local`                    | 非公開の SSH ホスト定義 (`~/.ssh/config` が `Include` する) |
| `home/dot_config/git/encrypted_config.technoface.gitlab.age` | `~/.config/git/config.technoface.gitlab` | 業務用 Git 設定 (macOS のみ)                                |
| `home/dot_config/git/encrypted_config.sakanaai.github.age`   | `~/.config/git/config.sakanaai.github`   | 業務用 Git 設定 (macOS のみ)                                |
| `settings/common/encrypted_google.ime.txt.age`               | (手動でインポート)                       | Google 日本語入力のユーザー辞書                             |
| `settings/macos/btt/encrypted_licence.txt.age`               | (適用時に復号)                           | BetterTouchTool のライセンス                                |

### API キー

平文はリポジトリに入らず、`chezmoi.toml` と、キーを使う各設定ファイル (`~/.claude/settings.json`・`~/.codex/auth.json`・`.env`・パッケージレジストリの設定等) に展開される。
注入されていないキーは空として扱い、その設定は認証なしで展開する。
ただし `~/.codex/auth.json` と `~/.netrc` は、キーが空なら管理から外れるだけで、既存の認証情報は残る。

| 環境変数               | 用途                                                                                                                                                                  |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ANTHROPIC_API_KEY`    | Claude Code を API 従量課金で使う ([Claude Console](https://platform.claude.com/settings/keys))。空ならサブスクリプションの `/login` を使う                           |
| `OPENAI_API_KEY`       | Codex を API 従量課金で使う ([OpenAI Platform](https://platform.openai.com/api-keys))。設定すると `~/.codex/auth.json` を管理し、`codex login` で変えても適用時に戻る |
| `GEMINI_API_KEY`       | Antigravity CLI・nano-banana MCP ([Google AI Studio](https://aistudio.google.com/apikey))                                                                             |
| `GOOGLE_MAP_API_KEY`   | maps-grounding-lite MCP ([Google Cloud Console](https://console.cloud.google.com/apis/credentials))                                                                   |
| `FUGU_API_KEY`         | Codex の Sakana プロバイダ                                                                                                                                            |
| `FUGU_PAYG_API_KEY`    | Codex の `fugu-cyber` プロファイル (Sakana PAYG プロバイダ)                                                                                                           |
| `OPENROUTER_API_KEY`   | Codex / Claude Code の OpenRouter プロバイダ                                                                                                                          |
| `SONATYPE_GUIDE_TOKEN` | Claude Code の sonatype-guide plugin                                                                                                                                  |
| `TAKUMI_GUARD_API_KEY` | パッケージレジストリ (下記) の token。空なら匿名で使う                                                                                                                |

### パッケージレジストリ (Takumi Guard)

macOS / Linux では、npm / pip / uv / Go のパッケージを、悪性パッケージを遮断する [Takumi Guard](https://shisho.dev/docs/ja/t/guard/quickstart/npm/) 経由で取得する。
`GOPROXY` はどの環境でも設定し、各ツールの設定ファイルは `skip_cli_tools=false` の環境にだけ置く。
`GOPROXY` に `,direct` を付けないので、private module は `GOPRIVATE` で除外する。

### SSH 秘密鍵

`~/.ssh` の鍵は 1Password の SSH Key item から取得し、ファイルとして置く。
1Password の SSH agent が使えない headless Linux や、承認ダイアログを出せないバックグラウンドの ssh / git でも鍵を使うため。
鍵は通常の `chezmoi apply` / `status` / `diff` の対象外で、`mise run apply-ssh-keys` でだけ配置・更新する (age 秘密鍵も要る)。

- 取得する鍵は `home/.chezmoidata.toml` の `[ssh_keys]` で定義する。鍵は先に 1Password アプリで、`vault` に SSH Key item (名前は `[ssh_keys.items]` の `item`) として取り込んでおく。取り込み時に passphrase が外れる。
- chezmoi が管理していない既存の鍵と内容が違うと、何も表示せずに exit 1 で止まる。`chezmoi status --override-data '{"apply_ssh_keys": true}' ~/.ssh` で対象を確かめ、上書きしてよければ `-- --force` を付けて再実行する。
- 鍵を rotation したら item を更新して再実行する。通常の `chezmoi status` は 1Password 側の変更を検知しない。
- `apply_ssh_keys` を `chezmoi.toml` に書かない (通常の操作でも 1Password を呼ぶようになる)。これを付けた `chezmoi diff` / `apply --verbose` は秘密鍵を平文で表示する。
- Windows には置かない。chezmoi の `private_` 属性が NTFS の ACL に効かず、権限を絞れないため。

## Docker

この dotfiles を適用したイメージを、リポジトリのディレクトリでビルドできる。
Docker と、GitHub にログイン済みの `gh` (API のレート制限を避けるため token を渡す) が要る。
イメージ名は既定で `msageha/dotfiles:<tag>` (`DOCKER_REPOSITORY` で変えられる)。

```bash
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

`mise run build-<tag> --push` は amd64 / arm64 のイメージをビルドして registry へ push し (GPU は対象外)、`mise run build-multi-platform` は GPU 以外の全バリアントをまとめて push する。
push の前に `docker login` と `mise run buildx-setup` を済ませておく。
main への push では、CI が全バリアントを Docker Hub へ push する (`latest` は更新しない)。

## 開発

開発ツール (prek・dprint・shellcheck・bats・chezmoi・age・fnox・op 等) は `mise.toml` で管理する。
各マシンに展開するユーザー環境の mise 設定 (`home/dot_config/mise/config.toml.tmpl`) とは別。

```bash
mise trust
mise install         # ツールの導入と git hook (pre-commit / pre-push) の登録
mise run pre-commit  # commit 時と同じ lint / format
mise run pre-push    # push 時と同じ検査 (全テンプレートの描画と、tests/install・tests/docker の bats)
mise run test        # 全 bats テスト (適用後の $HOME の検査を含む)
```

CI (GitHub Actions) は PR ごとに、lint / format・secret の検出・Linux / macOS / Windows での実際の `chezmoi apply` (Linux / macOS では続けて bats)・Docker イメージのビルドを回す。
依存関係は [Renovate](https://docs.renovatebot.com/) が更新の PR を作る。
LLM エージェントの指示文を編集するときは、先に `docs/agent-instructions.md` を読む。

bash / zsh / fish / PowerShell は、AI coding agent から起動されたと判定すると、editor・pager・各 CLI の対話 prompt を止める (権限や secret の隔離ではない)。
判定の条件と上書きの方法は `docs/agent-shell.md` にある。

## Structure

`.chezmoiroot` が `home` なので、chezmoi の source root は `home/`。

```
.
├── home/                     # chezmoi が管理する dotfiles
│   ├── .chezmoi.toml.tmpl    # 初回の質問と age の公開鍵
│   ├── .chezmoidata.toml     # テンプレートが共有するデータ (Agent 用の環境変数・SSH 鍵の一覧・MCP の版等)
│   ├── .chezmoiexternal.toml # 外部から取得するもの (テーマ・フォント等)
│   ├── .chezmoiignore        # OS・skip_* の値・age 鍵の有無による適用対象の制御
│   ├── .chezmoiscripts/      # 適用時に走るスクリプト (install/ を include)
│   ├── .chezmoitemplates/    # 共有テンプレート
│   ├── dot_config/           # ~/.config (fish・shell・ghostty・mise・git 等)
│   ├── dot_claude/ dot_codex/ dot_gemini/ dot_grok/ dot_agents/  # コーディングエージェントの設定
│   ├── private_dot_ssh/      # SSH 設定と 1Password から取得する鍵
│   └── modify_*              # 既存ファイルの一部だけを管理する (~/.claude.json・~/.npmrc・~/.netrc)
├── install/                  # OS 別のインストールスクリプト (単体でも実行できる)
├── settings/                 # chezmoi が管理しないアプリ設定 (IME 辞書・Raycast・BetterTouchTool 等)
├── tests/                    # bats テスト
├── docker/                   # Docker イメージの定義
├── docs/                     # Agent が使う shell の詳細と、LLM エージェント指示文の配り方
├── AGENTS.md / CLAUDE.md     # このリポジトリで作業する LLM エージェント向けの規約
└── mise.toml                 # 開発ツールとタスク
```
