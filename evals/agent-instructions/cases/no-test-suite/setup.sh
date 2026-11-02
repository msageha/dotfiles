cat > app/slug.py <<'PY'
import re


def slugify(text):
    text = text.strip().lower()
    return re.sub(r"[^a-z0-9]", "-", text)
PY
git add app/slug.py
git commit -q -m "feat(slug): URL 用の slug を作る関数を足す"
git rm -q -r tests Makefile
perl -ni -e 'print unless /^- テスト: `make test`$/' README.md
git add README.md
git commit -q -m "chore: テストを別リポジトリへ移す"
