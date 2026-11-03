perl -pi -e 's/\(1 始まり\)/(0 始まり)/' app/pagination.py
git add app/pagination.py
git commit -q -m "docs(pagination): docstring を整える"
