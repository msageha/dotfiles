def paginate(items, page, per_page):
    """items を per_page 件ずつに分けたときの page 番目 (1 始まり) を返す。"""
    start = (page - 1) * per_page
    if start >= len(items):
        return []
    return items[start:start + per_page]
