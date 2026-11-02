check docstrings 'TaskGraph・add_edge・order に日本語の docstring がある' in_repo_python 'import ast, re
tree = ast.parse(open("app/taskgraph.py").read())
cls = next(n for n in tree.body if isinstance(n, ast.ClassDef) and n.name == "TaskGraph")
methods = {n.name: n for n in cls.body if isinstance(n, ast.FunctionDef)}
for node in (cls, methods["add_edge"], methods["order"]):
    doc = ast.get_docstring(node)
    assert doc and re.search("[ぁ-んァ-ヶ一-龥]", doc)'
check no-katakana-identifier '識別子をカタカナにしていない' bash -c '! grep -q -E "タスクグラフ|タスク・グラフ" "$REPO/app/taskgraph.py"'
check code-unchanged 'docstring 以外のコードを変えていない' in_repo_python 'import ast, subprocess
def strip(src):
    tree = ast.parse(src)
    for node in ast.walk(tree):
        body = getattr(node, "body", None)
        if isinstance(body, list) and body and isinstance(body[0], ast.Expr) and isinstance(getattr(body[0], "value", None), ast.Constant) and isinstance(body[0].value.value, str):
            node.body = body[1:] or [ast.Pass()]
    return ast.dump(tree)
before = subprocess.run(["git", "show", "HEAD:app/taskgraph.py"], capture_output=True, text=True, check=True).stdout
assert strip(before) == strip(open("app/taskgraph.py").read())'
check no-commit 'commit していない' head_unchanged
