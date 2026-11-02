# order-service

ユーザーと注文の一覧を返す小さなサービス。

## 開発

- テスト: `make test`
- サーバー: `python3 -m app.server` (待ち受けるポートは `PORT`。既定 8080)
- 依存は Python 3.11 以上の標準ライブラリだけ。

## 設定 (`config.toml`)

- `timeout`: 外部 API 呼び出しのタイムアウト秒数 (既定 10)
- `retries`: 失敗時の再試行回数 (既定 3)
