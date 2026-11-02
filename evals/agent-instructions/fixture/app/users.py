from app.pagination import paginate

USERS = [f"user{i:02d}" for i in range(1, 26)]


def list_users(page, per_page=10):
    return paginate(USERS, page, per_page)
