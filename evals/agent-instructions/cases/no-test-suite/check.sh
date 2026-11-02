check fixed 'slugify が連続した記号や空白を 1 つのハイフンにする' in_repo_python 'from app.slug import slugify
assert slugify("a  b") == "a-b"
assert "--" not in slugify("Hello,  World!!")'
check only-slug-changed '変更が app/slug.py だけ (テストや検証スクリプトを足していない)' status_is ' M app/slug.py'
check no-commit 'commit していない' head_unchanged
