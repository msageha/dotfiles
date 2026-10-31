---
name: improve-pr
description: "Scrutinizes a PR or branch diff against the purpose of the change and improves it, for requests such as 「PR を精査して改善して」「main との差分を確認して改善して」「merge するべきか確認して」「この PR に問題ないか確認して」. Identifies the goal first, then checks structure and responsibilities before functions, naming and comments: dead or redundant code, over-engineering, out-of-scope changes, hidden failures, the split between LLM output and deterministic harness code, and prompt quality. Evaluation-only requests get a read-only report with a merge verdict; improvement requests get fixes within the PR's purpose, verified. Use when the user asks to scrutinize, improve or judge whether to merge a PR or branch; for a findings-only code review, use review instead."
argument-hint: "[PR number / URL / branch]"
---

# PR の精査と改善

PR やブランチの差分を、その変更が達成したい目的に照らして精査し、依頼に応じて改善する。対象は引数 (`$ARGUMENTS`。空または置換されない場合は依頼文) で指定された PR 番号・URL・ブランチで、指定が無ければ現在のブランチとする。

## モードと許可の範囲

最初に依頼文からモードを決め、以降はその範囲で動く。

- 評価: 「確認して」「問題ない？」「merge するべき？」など。read-only で進め、所見と merge の判定を報告して止まる。ファイル・ブランチ・PR は変えない。
- 改善: 「改善して」「修正して」「確認して、問題があれば直して」など。PR の目的の範囲で修正を適用し、検証まで行う。
- 変更の規模の既定は、PR の目的と本質を保ったままの改善 (ファイル分割・関数名の変更・コメントの短縮を含む)。大規模な再設計と、後方互換の無い破壊的変更 (DB スキーマの変更を含む) は、依頼文が許可したときだけ適用の候補にする。許可が無ければ、利点・コスト・移行の影響を添えた提案に留める。
- commit・push・PR 本文の更新は、依頼文にあるときだけ行う (AGENTS.md の `git` 節。手順は commit / pr skill)。
- 同じ PR の再精査を頼まれたら (「改めて」の有無や、別のセッションかどうかを問わず)、前回の結論に頼らず最初からやり直す。

## 1. 差分と目的をつかむ

- 最初に対象の head と base を決める。PR なら `gh pr view <pr> --json title,body,baseRefName,headRefName,headRefOid,comments,reviews` (GitLab は `glab mr view`) で両方を取り、`git fetch origin <base> pull/<pr>/head` (GitLab は `merge-requests/<mr>/head`) で head の commit を取得して、`headRefOid` を `<head>` に使う (fork の PR も同じ手順で取れる)。ブランチ指定なら `git fetch origin <base> <branch>` のあと `origin/<branch>` (ローカルにしか無いブランチはそのまま)、指定が無ければ現在のブランチ (`HEAD`) を `<head>` にする。base は PR の base、無ければリポジトリの既定ブランチ。
- 差分を出力する前に `git diff --name-only origin/<base>...<head>` (PR は `gh pr diff <pr> --name-only`) でパスを確かめ、secret ファイル (`.env*`・鍵・token を含むファイル) は中身を出さずに変更の有無だけを見る。出力した secret は取り消せないため、判定を先に行う。
- 差分は head を明示して取る (`git log --oneline origin/<base>..<head>`、`git diff origin/<base>...<head> -- . ':(exclude)<secret>'`。PR は `gh pr diff <pr> --exclude '<secret>'` も読む)。three-dot にするのは、base 側に後から入った変更を差分に混ぜないため。現在のブランチが head でないとき、評価モードでは checkout せず `git show <head>:<path>` で読む。改善モードでは作業ツリーを head に合わせてから修正し (PR は `gh pr checkout <pr>`。未 commit の変更があれば checkout せず報告して止まる)、修正後に `git diff origin/<base>...HEAD` が対象の差分であることを確かめる。
- PR 本文・commit message・関連 issue・レビューコメントを読み、この変更が達成したい目的と本質を一文で言えるまで特定する。今の実装の形に引っ張られず、目的から見て施策そのものが妥当か、より軽い手段 (既存の仕組みの延長) で足りないかを先に判断する。
- 既存のテスト・既存の実装・言語別の rule の既定は正本として扱わず、目的に照らして判断する。テストが誤っている可能性もあるので、設計を判断する間はテストをいったん脇に置く。
- 関連する他の PR / issue (同じファイルや目的を扱うもの、stacked PR の親子) を `gh pr list --search "<keywords>"` 等で探し、責務や目的の重複・衝突が無いかを確かめる。
- レビューコメントがあれば、字面だけでなく、なぜその指摘をしたのか (同じレビュアーの他の指摘や過去の PR に表れた考え方・文言) をつかんでから扱う。対応も頼まれたら、コメント単位で対応済み / 未対応とその理由を報告する。

## 2. マクロ: 構造と責務

一巡目から次の観点を全て見る。

- 目的に属さない変更の混入 (ついでの修正・別の関心事・頼まれていない指示文の改変)。
- 責務の配置: 処理が責務を所有するモジュールにあるか。特定の機能・利用側に固有の処理が汎用層に漏れていないか。ファイル分割が役割に沿っているか。
- 過剰設計: 現に要求されていない抽象・汎用化・設定項目・互換レイヤーや、起こり得ない状態への防御。
- 失敗の隠蔽: 成功率や安定性を上げる変更が、本来 partial / failed の結果を成功に見せていないか、記録の無いまま情報を落としていないか、上限の撤廃で暴走しないか。切り詰めるなら、その事実と状態を記録しているか。
- LLM を組み込むシステムの責務分担: 検証・照合・集計・転記・状態管理などコードで決定論的に書ける処理を、LLM の出力に任せていないか。ハーネス (コード) 側に寄せられるものは寄せ、LLM には非決定的な判断だけを残す。変更で LLM の責務が増えていないか。
- プロンプト資産 (LLM に渡す指示文・skill・コード内のプロンプト・schema の description): LLM が実行時に受け取る情報だけで遂行できるか (ハーネスの実装や特定の対象の具体値を前提にしていないか)。冗長・長すぎ・曖昧・矛盾が無いか。混入を 1 つ見つけたら同種の箇所まで洗い出す。
- 成果物を使う当事者 (エンドユーザー・運用者・顧客など) の立場から見て、目的に届く品質か。

## 3. ミクロ: 実装の細部

- デッドコード・冗長なコード・重複と、もっと簡潔に書ける箇所。
- 関数・モジュールの粒度 (1 箇所からしか呼ばれない薄い wrapper 等)。
- 命名: 内容と適用範囲が読める具体名か、隣接コードの規約に揃っているか。
- コメント・docstring: コードから読み取れない情報だけを書いているか、実装と一致しているか、短くできないか。
- テストの都合による本番コードの歪み: テスト専用の分岐、条件の緩和、patch のための注入点や定数化。
- 造語・内部ラベル: 識別子・UI 文言・ログ・プロンプト・PR 本文に、一般的でない用語や作業中のラベルが入っていないか。

## 4. 別のモデル・エージェントのレビュー

- 推奨が割れる判断は、ユーザーに返す前に、使える環境なら別のモデル・エージェントにも同じ問いを投げて結論を固める。改善を一巡したら、目的・差分の範囲・自分で実行した検証の結果を渡してレビューを頼む。
- 受け取った指摘は鵜呑みにせず、項目ごとにコードと実測で再評価して採否を決め、却下したものは理由を報告に書く。
- 改善モードでは、裏付けのある指摘が尽きるまで修正と再レビューを繰り返す。

## 5. 適用と検証 (改善モード)

- 所見を、目的に必要な修正・目的の範囲の改善・範囲外 (別 PR の候補) に分け、前の 2 つを適用する。
- 既存の lint / test / build を実行する。テストが新しい設計と食い違えば、実装をあるべき形にしてからテストを追従させる。仕様の変更を伴うテストの修正は着手前に確認する。

## 6. 報告

AGENTS.md の「成果物と報告」節に従い、次を含める。

- 冒頭に、目的の一文と結論 (評価なら merge の判定、改善なら適用した変更の要約)。
- merge の判定: 「merge してよいか (可)」「merge すべきか (推奨)」「merge 前に直すべき点」を分け、得られるもの・失うもの・デグレ・破壊的変更の有無・セキュリティリスク・他の PR への影響を根拠付きで書く。
- 変更前や別の PR と比べるときは、違いだけでなく、共通点・旧版が優れていた点・デグレになる点も挙げる。
- 観点ごとの判定を、問題なしと判断したものも含めて並べ、残りの指摘が無いと言える根拠にする。
- 所見のラベルは、初出で内容が分かる見出しと一緒に示す。
- 許可が無く適用しなかった大規模・破壊的な変更は、提案として挙げる。
