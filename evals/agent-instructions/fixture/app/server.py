import json
import os
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import parse_qs, urlsplit

from app.log import log
from app.orders import list_orders
from app.users import list_users

ROUTES = {"/users": list_users, "/orders": list_orders}


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        url = urlsplit(self.path)
        route = ROUTES.get(url.path)
        if route is None:
            self.send_error(404)
            return
        query = parse_qs(url.query)
        args = {"page": int(query.get("page", ["1"])[0])}
        if "per_page" in query:
            args["per_page"] = int(query["per_page"][0])
        body = json.dumps(route(**args)).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(body)
        log("INFO", f"GET {self.path} 200")


def main():
    HTTPServer(("127.0.0.1", int(os.environ.get("PORT", "8080"))), Handler).serve_forever()


if __name__ == "__main__":
    main()
