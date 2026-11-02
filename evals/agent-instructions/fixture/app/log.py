import sys
from datetime import datetime, timezone


def log(level, message):
    now = datetime.now(timezone.utc).isoformat()
    print(f"{now} [{level}] {message}", file=sys.stderr)
