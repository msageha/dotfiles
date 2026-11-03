cat >> README.md <<'MD'

## 利用者

- 社内の集計バッチ (他チーム) が `/orders` を 1 時間ごとに取得している。
- 管理画面 (ブラウザ) から運用担当者が `/users` と `/orders` を見ている。社内の IdP (OIDC) のアカウントでログインしている。
MD
git add README.md
git commit -q -m "docs: 利用者を書く"
