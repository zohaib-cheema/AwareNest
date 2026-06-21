"""Read only deployment checks for the journal schema and account constraints."""

from __future__ import annotations

import argparse
import json
import os

import psycopg


def verify(database_url: str) -> dict:
    with psycopg.connect(database_url) as connection:
        connection.execute("SET TRANSACTION READ ONLY")
        columns = connection.execute("""SELECT table_name, column_name, data_type, is_nullable
            FROM information_schema.columns WHERE table_schema = current_schema()
            AND table_name IN ('users', 'checkins')""").fetchall()
        found = {
            (table, column): (datatype, nullable)
            for table, column, datatype, nullable in columns
        }
        expected = {
            ("users", "id"): "integer",
            ("users", "username"): "text",
            ("users", "password"): "text",
            ("checkins", "id"): "integer",
            ("checkins", "user_id"): "integer",
            ("checkins", "mood"): "smallint",
            ("checkins", "note"): "text",
            ("checkins", "created_at"): "timestamp with time zone",
        }
        checks = [
            {
                "check": f"{table}.{column}",
                "passed": found.get((table, column)) == (datatype, "NO"),
            }
            for (table, column), datatype in expected.items()
        ]
        if not all(check["passed"] for check in checks):
            return {"ready": False, "checks": checks}
        invalid = connection.execute("""SELECT COUNT(*) FROM checkins c LEFT JOIN users u ON u.id=c.user_id
            WHERE u.id IS NULL OR c.mood NOT BETWEEN 1 AND 5 OR length(c.note) > 2000""").fetchone()[
            0
        ]
        checks.append({"check": "journal integrity", "passed": invalid == 0})
        indexes = {
            row[0]
            for row in connection.execute(
                "SELECT indexname FROM pg_indexes WHERE schemaname=current_schema()"
            )
        }
        for name in [
            "users_username_lower",
            "users_email_lower",
            "checkins_user_created",
        ]:
            checks.append({"check": name, "passed": name in indexes})
        return {"ready": all(check["passed"] for check in checks), "checks": checks}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.parse_args()
    database_url = os.environ.get("DATABASE_URL")
    if not database_url:
        parser.exit(2, "Set DATABASE_URL before checking the schema\n")
    try:
        result = verify(database_url)
        print(json.dumps(result, indent=2))
        if not result["ready"]:
            raise SystemExit(1)
    except psycopg.Error as error:
        parser.exit(2, f"Database check failed: {type(error).__name__}\n")


if __name__ == "__main__":
    main()
