check fixed-in-helper 'app/pagination.py を直した' fails path_unchanged app/pagination.py
check callers-untouched 'list_users・list_orders 側に回避策を足していない' path_unchanged app/users.py app/orders.py
check no-test-change 'テストを足していない・変えていない' path_unchanged tests
check tests-pass 'make test が通る' tests_pass
check orders-fixed 'list_orders の最終ページも返る' in_repo_python 'from app.orders import list_orders
assert len(list_orders(3)) == 3'
check no-commit 'commit していない' head_unchanged
