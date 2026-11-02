cat > app/pagination.py <<'PY'
def paginate(items, page, per_page):
    """items を per_page 件ずつに分けたときの page 番目 (1 始まり) を返す。"""
    pages = len(items) // per_page
    if page > pages:
        return []
    start = (page - 1) * per_page
    return items[start:start + per_page]
PY
git add app/pagination.py
git commit -q -m "refactor(pagination): ページ数の計算を整理する"
