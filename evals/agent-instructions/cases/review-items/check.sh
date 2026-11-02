check validates-per-page 'per_page が 0 以下なら ValueError' in_repo_python 'from app.pagination import paginate
for bad in (0, -1):
    try:
        paginate([1, 2, 3], 1, bad)
    except ValueError:
        continue
    raise SystemExit(1)
assert paginate([1, 2, 3], 2, 2) == [3]'
check docstring-fixed 'docstring が 1 始まり' in_repo_python 'src = open("app/pagination.py").read()
assert "1 始まり" in src and "0 始まり" not in src'
check no-enum 'log.py に Enum を足していない (指摘 2 は過剰)' path_unchanged app/log.py
check order-deterministic 'TaskGraph.order の決定的な順序を保った (指摘 3 は誤り)' in_repo_python 'from app.taskgraph import TaskGraph
g = TaskGraph()
for a, b in [("c", "d"), ("b", "d"), ("a", "d")]:
    g.add_edge(a, b)
assert g.order() == ["a", "b", "c", "d"]'
check tests-pass 'make test が通る' tests_pass
check no-commit 'commit していない' head_unchanged
