perl -pi -e 's/^def list_users\(page, per_page=10\):$/def fetch_users(page, per_page=10):/' app/users.py
