"""Export one account's journal from an administrator controlled database."""

from __future__ import annotations

import argparse
import csv
import json
import os
from pathlib import Path

import psycopg
from psycopg.rows import dict_row


def fetch_entries(database_url: str, user_id: int) -> list[dict]:
    if user_id <= 0:
        raise ValueError("The account ID must be positive")
    with psycopg.connect(database_url, row_factory=dict_row) as connection:
        connection.execute("SET TRANSACTION READ ONLY")
        found = connection.execute(
            "SELECT id FROM users WHERE id = %s", (user_id,)
        ).fetchone()
        if found is None:
            raise ValueError("The account was not found")
        return list(
            connection.execute(
                "SELECT id, mood, note, created_at FROM checkins WHERE user_id = %s ORDER BY created_at, id",
                (user_id,),
            )
        )


def safe_cell(value):
    if isinstance(value, str) and value.lstrip().startswith(("=", "+", "-", "@")):
        return "'" + value
    return value


def write_export(entries: list[dict], destination: Path, format: str = "json") -> Path:
    if format not in {"json", "csv"}:
        raise ValueError("Choose json or csv")
    # Exclusive creation prevents accidentally replacing an earlier export.
    descriptor = os.open(destination, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(descriptor, "w", encoding="utf-8", newline="") as stream:
        if format == "json":
            json.dump(
                entries, stream, indent=2, default=lambda value: value.isoformat()
            )
            stream.write("\n")
        else:
            writer = csv.DictWriter(
                stream, fieldnames=["id", "mood", "note", "created_at"]
            )
            writer.writeheader()
            writer.writerows(
                {key: safe_cell(value) for key, value in entry.items()}
                for entry in entries
            )
    return destination


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--user-id", required=True, type=int)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--format", choices=["json", "csv"], default="json")
    args = parser.parse_args()
    try:
        database_url = os.environ.get("DATABASE_URL")
        if not database_url:
            raise ValueError("Set DATABASE_URL before exporting")
        entries = fetch_entries(database_url, args.user_id)
        write_export(entries, args.output, args.format)
        print(f"Exported {len(entries)} entries to a private file at {args.output}")
    except (OSError, ValueError, psycopg.Error) as error:
        parser.exit(
            2,
            f"Export failed: {str(error) if isinstance(error, ValueError) else type(error).__name__}\n",
        )


if __name__ == "__main__":
    main()
