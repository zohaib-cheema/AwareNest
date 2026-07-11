"""Create private local development settings without printing credentials."""

from __future__ import annotations

import argparse
import os
import secrets
from pathlib import Path


def configure(destination: Path, port: int = 55432) -> Path:
    if not 1024 <= port <= 65535:
        raise ValueError("Choose a port between 1024 and 65535")
    password = secrets.token_hex(24)
    content = (
        f"POSTGRES_PASSWORD={password}\n"
        f"DATABASE_URL=postgresql://awarenest:{password}@127.0.0.1:{port}/awarenest\n"
        f"JWT_SECRET={secrets.token_hex(32)}\n"
        "WEB_ORIGIN=http://127.0.0.1:5173,http://localhost:5173,http://127.0.0.1:3000\n"
    )
    descriptor = os.open(destination, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(descriptor, "w", encoding="utf-8") as stream:
        stream.write(content)
    return destination


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output", type=Path, default=Path(__file__).resolve().parents[1] / ".env"
    )
    args = parser.parse_args()
    try:
        print(f"Created private settings at {configure(args.output)}")
    except (OSError, ValueError) as error:
        parser.exit(2, f"Error: {error}\n")


if __name__ == "__main__":
    main()
