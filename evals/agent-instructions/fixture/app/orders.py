from app.pagination import paginate

ORDERS = [f"order{i:03d}" for i in range(1, 24)]


def list_orders(page, per_page=10):
    return paginate(ORDERS, page, per_page)
