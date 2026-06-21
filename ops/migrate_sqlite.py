"""Move legacy users to PostgreSQL while preserving IDs and bcrypt hashes.

The default command only checks the source. Applying a migration requires an
explicit flag and an empty target users table. The source is always read only.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sqlite3
from dataclasses import dataclass
from pathlib import Path

import psycopg


@dataclass(frozen=True)
class User:
    id: int
    username: str
    password: str
    email: str | None
    phone: str | None


@dataclass(frozen=True)
class Source:
    users: tuple[User, ...]
    fingerprint: str

    def summary(self) -> dict:
        return {
            "users": len(self.users),
            "snapshot_sha256": self.fingerprint,
            "source_mode": "read only",
            "password_handling": "bcrypt hashes preserved",
        }


def read_source(source: Path) -> Source:
    if not source.is_file():
        raise ValueError("The source database does not exist")
    connection = sqlite3.connect(source.resolve().as_uri() + "?mode=ro", uri=True)
    connection.row_factory = sqlite3.Row
    try:
        connection.execute("BEGIN")
        if connection.execute("PRAGMA integrity_check").fetchone()[0] != "ok":
            raise ValueError("The source database failed its integrity check")
        columns = {
            row["name"] for row in connection.execute("PRAGMA table_info(users)")
        }
        if not {"id", "username", "password", "email", "phone"}.issubset(columns):
            raise ValueError(
                "The legacy users table does not match the expected schema"
            )
        rows = connection.execute(
            "SELECT id, username, password, email, phone FROM users ORDER BY id"
        ).fetchall()
        fingerprint = hashlib.sha256(connection.serialize()).hexdigest()
        usernames, emails, identifiers, users = set(), set(), set(), []
        for row in rows:
            identifier, username, password = row["id"], row["username"], row["password"]
            if (
                not isinstance(identifier, int)
                or identifier <= 0
                or identifier in identifiers
            ):
                raise ValueError("Legacy users contain invalid or repeated IDs")
            if not isinstance(username, str) or not 3 <= len(username.strip()) <= 40:
                raise ValueError(
                    f"User ID {identifier} needs a valid name before migration"
                )
            username = username.strip()
            if username.casefold() in usernames:
                raise ValueError("Legacy names are not unique when case is ignored")
            if not isinstance(password, str) or not re.fullmatch(
                r"\$2[aby]\$\d{2}\$[./A-Za-z0-9]{53}", password
            ):
                raise ValueError(
                    f"User ID {identifier} does not have a supported bcrypt hash"
                )
            email = row["email"]
            if email is not None and not isinstance(email, str):
                raise ValueError(f"User ID {identifier} has an invalid email value")
            email = email.strip().lower() if email and email.strip() else None
            if email and email in emails:
                raise ValueError(
                    "Legacy email addresses are not unique when case is ignored"
                )
            phone = row["phone"]
            if phone is not None and not isinstance(phone, str):
                raise ValueError(f"User ID {identifier} has an invalid phone value")
            identifiers.add(identifier)
            usernames.add(username.casefold())
            if email:
                emails.add(email)
            users.append(User(identifier, username, password, email, phone))
        return Source(tuple(users), fingerprint)
    finally:
        connection.close()


def migrate(source: Source, database_url: str, schema: str = "public") -> dict:
    if not re.fullmatch(r"[a-zA-Z_][a-zA-Z0-9_]*", schema):
        raise ValueError("Invalid schema name")
    sql = Path(__file__).resolve().parents[1] / "backend/sql/001_init.sql"
    with psycopg.connect(
        database_url, options=f"-c search_path={schema}"
    ) as connection:
        with connection.transaction():
            connection.execute("SET TRANSACTION ISOLATION LEVEL SERIALIZABLE")
            connection.execute("SELECT pg_advisory_xact_lock(674319092)")
            connection.execute(sql.read_text())
            connection.execute("""CREATE TABLE IF NOT EXISTS legacy_imports (
                fingerprint TEXT PRIMARY KEY,
                user_count INTEGER NOT NULL,
                applied_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
            )""")
            existing = connection.execute(
                "SELECT user_count FROM legacy_imports WHERE fingerprint = %s",
                (source.fingerprint,),
            ).fetchone()
            if existing:
                return {"status": "already applied", **source.summary()}
            count = connection.execute("SELECT COUNT(*) FROM users").fetchone()[0]
            if count:
                raise ValueError(
                    "The target users table must be empty before importing a new snapshot"
                )
            with connection.cursor() as cursor:
                cursor.executemany(
                    "INSERT INTO users (id, username, password, email, phone) VALUES (%s, %s, %s, %s, %s)",
                    [
                        (user.id, user.username, user.password, user.email, user.phone)
                        for user in source.users
                    ],
                )
            connection.execute(
                "SELECT setval(pg_get_serial_sequence('users', 'id'), COALESCE(MAX(id), 1), COUNT(*) > 0) FROM users"
            )
            connection.execute(
                "INSERT INTO legacy_imports(fingerprint, user_count) VALUES (%s, %s)",
                (source.fingerprint, len(source.users)),
            )
    return {"status": "applied", **source.summary()}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument(
        "--apply", action="store_true", help="Import into an empty target"
    )
    args = parser.parse_args()
    try:
        source = read_source(args.source)
        if args.apply:
            database_url = os.environ.get("DATABASE_URL")
            if not database_url:
                raise ValueError("Set DATABASE_URL before applying a migration")
            result = migrate(source, database_url)
        else:
            result = {"status": "checked only", **source.summary()}
        print(json.dumps(result, indent=2))
    except (OSError, ValueError, sqlite3.Error, psycopg.Error) as error:
        # Database exception strings may contain connection details or row values.
        message = (
            str(error)
            if isinstance(error, (ValueError, FileNotFoundError))
            else type(error).__name__
        )
        parser.exit(2, f"Migration failed: {message}\n")


if __name__ == "__main__":
    main()
