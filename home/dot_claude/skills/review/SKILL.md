---
name: review
description: Reviews uncommitted changes, the current branch's diff against its base, or a PR given by number / URL as a senior engineer across correctness, security, performance, readability, maintainability, and whether the change should be made at all, and can post the findings to the PR as a pending review. Use when the user asks for a code review (「レビューして」「この PR を見て」「差分を確認して」「PR にレビューコメントをつけて」) or a comparison of two changes or PRs. To judge a PR against its purpose with a merge verdict, or to improve it, use improve-pr instead.
allowed-tools: Read, Grep, Glob, Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git show:*), Bash(gh pr diff:*), Bash(gh pr view:*)
disallowed-tools: Edit, Write, NotebookEdit
---

# コードレビュー

作業ツリーの未 commit の変更 (unstaged と staged の両方、untracked の新規ファイルを含む)、それが無ければ base ブランチとの差分、または指定された PR をレビューする。ソースや追跡ファイルは編集しない (lint / test 等の検証の実行で生じるキャッシュ・ビルド出力は想定内で、追跡ファイルが変わったら報告する。PR へのコメント投稿は、依頼されたときだけ Step 4 の手順で行う)。

## Step 1: 変更の取得

1. 中身を出さずにパスを把握する: `git status --short` (untracked の新規ファイルも対象)、`git diff HEAD --stat`、`git diff HEAD --name-only` (PR は `gh pr diff <pr> --name-only`)。`git diff HEAD` は unstaged と staged を合わせて比べる (`git diff` だけでは staged が漏れる)。
2. secret ファイル (`.env*`・鍵・token を含むファイル・`auth.json` 等) を判定する。出力した secret は取り消せないため、中身を出す前に行う。secret ファイルは中身を出さず、変更の有無だけを見る。
3. 差分本体を、secret ファイルを除いて取得する (`git diff HEAD -- . ':(exclude)<path>'`)。untracked の新規ファイルは、secret でないものの中身を読む。

レビュー対象が PR 番号 / URL で指定されたときは、代わりに `gh pr view <pr>` で説明を、`gh pr diff <pr> --exclude '<secret>'` で secret ファイルを除いた差分を取得する。

未 commit の変更が無ければ、base ブランチとの差分 (`git diff origin/<base>...HEAD`。three-dot で merge-base から比べ、base 側だけで進んだ変更を混ぜない。base は呼び出し元の指定、無ければ `origin/HEAD`) を対象にする。いずれも無ければレビュー対象を確認事項として呼び出し元に返す。

## Step 2: レビュー

1. まず変更の全体像を把握し、変更の意図を推測する。
2. 各ファイルの変更を以下の観点で精査する:
   - **正確性**: ロジックの誤り、エッジケースの見落とし、off-by-one エラー
   - **セキュリティ**: インジェクション、XSS、認証・認可の不備、機密情報の露出
   - **パフォーマンス**: 不要なループ、N+1 クエリ、メモリリーク
   - **可読性**: 命名の適切さ、過度な複雑性、マジックナンバー
   - **保守性**: 現に 2 箇所以上へ現れた同一ロジックの重複 (責務を利用側に閉じるための類似関数の重複は指摘しない)、テスタビリティ
   - **設計・必要性**: 過剰設計 (現に要求されていない抽象・汎用化・互換レイヤー)、現実に起こり得ない事象への防護コード・validation、存在意義を一文で説明できない class や抽象、デッドコード、テストを通すためだけの本番コード、責務の誤配置
   - **方針**: 変更を入れること自体が妥当か。変更前の実装と比較し、入れない・既存の仕組みに委ねる選択肢や、柔軟性・性能・運用の劣化を判定する
   - **回帰**: 変更前と比べて劣化した点 (性能・出力品質・ツールの本質的な機能・read-only や tool 制限等の既存規約)。以前の方が良かった箇所は取り込み候補として個別に挙げる
   - **利用者の立場**: 成果物を使う当事者 (エンドユーザー・運用者・依頼文が示す立場。例: 脆弱性診断を行うセキュリティエンジニア) の目で見て品質が足りているか
   - **コメント・説明**: コードを読めば分かる自明なコメント、実装と一致しない docstring / description
   - **指示への忠実さ** (依頼文が示されたとき): 指示通りか、対応漏れ・スコープ外の変更が無いか
3. 必要に応じて関連ファイルを読み、変更のコンテキストを把握する。
4. PR 本文や報告のテスト結果 (件数・カバレッジ) は自分で実行して照合できた場合だけ確認済みとし、テストが無い変更箇所はカバレッジの穴として所見に挙げる。
5. 2 つの PR・設計・実装の比較を求められたときは、違いだけでなく、共通点、旧版 (比較元) が優れていた点、デグレになる点も対称に挙げる。

## Step 3: 出力フォーマット

各指摘に通番を付け、以下の形式で報告する:

### N. [Critical / Major / Minor / Nit] 指摘タイトル
- **ファイル**: `path/to/file:行番号`
- **確度**: High / Medium / Low と検証方法 (実行して確認 / 読解のみ)
- **問題**: 何が問題か
- **修正案**: どう修正すべきか (コード例があれば含める)

最後に、確認して問題なしと判断した観点を列挙し、総評を 1-2 文で記載する。指摘がなければ、確認した範囲と安全と判断した根拠を述べる。

## Step 4: PR へのレビューコメント投稿 (依頼されたときだけ)

- 投稿の前と文面を書き直した後に、各指摘の主張と修正案の両方を一次証拠 (コード・実行結果・公式ドキュメント) で裏取りし直す。誤り・不要な指摘・その分野の専門家から見て初歩的な指摘は投稿せず、計測できる懸念は計測してから書く。
- 既定では pending (draft) review として作り、submit はしない。ユーザーが最終確認してから submit するため。submit まで明示的に依頼されたときだけ submit する。
- 各コメントは該当する file:line に付け、他のコメントを参照せずに単独で読めるように、何が問題か、放置すると何が困るか、どう直すかを書く。
- 強さのラベル (must / IMO / nits 等) は重大度と、そのリポジトリ・その PR の既存コメントの流儀に合わせる。PR が持ち込んだ回帰か、PR 以前からある問題かを区別して書く。
- 投稿後は、投稿したコメントの一覧 (file:line と要旨) と、pending のまま残っていることを報告する。
