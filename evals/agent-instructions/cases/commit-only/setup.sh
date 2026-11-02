perl -pi -e 's/def list_orders\(page, per_page=10\):/def list_orders(page, per_page=20):/' app/orders.py
perl -pi -e 's/^(ユーザーと注文の一覧を返す小さなサービス。)$/$1注文一覧は既定で 1 ページ 20 件。/' README.md
