from __future__ import annotations

import importlib.util
import json
import os
import sqlite3
import stat
import subprocess
import sys
from pathlib import Path
from uuid import uuid4

import psycopg
import pytest

OPS = Path(__file__).resolve().parents[1]


def module(name):
    spec = importlib.util.spec_from_file_location(name, OPS / f"{name}.py")
    result = importlib.util.module_from_spec(spec)
    sys.modules[name] = result
    spec.loader.exec_module(result)
    return result


migration = module("migrate_sqlite")
exports = module("export_journal")
configure = module("configure_local")


@pytest.fixture
def legacy(tmp_path):
    hashed = subprocess.run(
        [
            "node",
            "-e",
            "process.stdout.write(require('bcryptjs').hashSync('migration test password',4))",
        ],
        cwd=OPS.parent,
        capture_output=True,
        text=True,
        check=True,
    ).stdout
    path = tmp_path / "legacy.db"
    with sqlite3.connect(path) as connection:
        connection.execute(
            "CREATE TABLE users (id INTEGER PRIMARY KEY, username TEXT, password TEXT, email TEXT, phone TEXT)"
        )
        connection.executemany(
            "INSERT INTO users VALUES (?, ?, ?, ?, ?)",
            [
                (4, "Alice", hashed, "ALICE@example.com", ""),
                (9, "Bob", hashed, "bob@example.com", None),
            ],
        )
    return path, hashed


@pytest.fixture
def target():
    database_url = os.environ.get("TEST_DATABASE_URL")
    if not database_url:
        pytest.fail("Set TEST_DATABASE_URL for PostgreSQL migration tests")
    schema = "migration_" + uuid4().hex[:12]
    with psycopg.connect(database_url, autocommit=True) as connection:
        connection.execute(f"CREATE SCHEMA {schema}")
    try:
        yield database_url, schema
    finally:
        with psycopg.connect(database_url, autocommit=True) as connection:
            connection.execute(f"DROP SCHEMA {schema} CASCADE")


def test_migration_preserves_hashes_ids_and_sequence(legacy, target):
    path, hashed = legacy
    before = path.read_bytes()
    source = migration.read_source(path)
    result = migration.migrate(source, *target)
    assert result["status"] == "applied"
    assert path.read_bytes() == before
    database_url, schema = target
    with psycopg.connect(
        database_url, options=f"-c search_path={schema}"
    ) as connection:
        users = connection.execute(
            "SELECT id, password, email FROM users ORDER BY id"
        ).fetchall()
        assert users == [
            (4, hashed, "alice@example.com"),
            (9, hashed, "bob@example.com"),
        ]
        identifier = connection.execute(
            "INSERT INTO users(username,password) VALUES ('New user', %s) RETURNING id",
            (hashed,),
        ).fetchone()[0]
        assert identifier > 9
    assert migration.migrate(source, *target)["status"] == "already applied"


def test_import_refuses_to_mix_two_snapshots(legacy, target):
    path, _ = legacy
    migration.migrate(migration.read_source(path), *target)
    with sqlite3.connect(path) as connection:
        connection.execute("UPDATE users SET username='Changed' WHERE id=4")
    with pytest.raises(ValueError, match="must be empty"):
        migration.migrate(migration.read_source(path), *target)
    with psycopg.connect(
        target[0], options=f"-c search_path={target[1]}"
    ) as connection:
        assert (
            connection.execute("SELECT username FROM users WHERE id=4").fetchone()[0]
            == "Alice"
        )


def test_preflight_rejects_plaintext_and_case_collisions(legacy):
    path, _ = legacy
    with sqlite3.connect(path) as connection:
        connection.execute("UPDATE users SET username='alice' WHERE id=9")
    with pytest.raises(ValueError, match="not unique"):
        migration.read_source(path)
    with sqlite3.connect(path) as connection:
        connection.execute(
            "UPDATE users SET username='Bob', password='plaintext' WHERE id=9"
        )
    with pytest.raises(ValueError, match="bcrypt"):
        migration.read_source(path)


def test_preflight_does_not_create_missing_source(tmp_path):
    path = tmp_path / "missing.db"
    with pytest.raises(ValueError, match="does not exist"):
        migration.read_source(path)
    assert not path.exists()


def test_configuration_creates_unique_private_credentials_and_does_not_overwrite(
    tmp_path,
):
    first = configure.configure(tmp_path / ".env")
    second = configure.configure(tmp_path / ".env.other")
    assert first.read_text() != second.read_text()
    assert stat.S_IMODE(first.stat().st_mode) == 0o600
    assert "JWT_SECRET=" in first.read_text()
    with pytest.raises(FileExistsError):
        configure.configure(first)


def test_exports_are_private_and_escape_spreadsheet_formulas(tmp_path):
    rows = [
        {
            "id": 1,
            "mood": 4,
            "note": "=HYPERLINK(1)",
            "created_at": "2026-11-02T12:00:00Z",
        }
    ]
    output = exports.write_export(rows, tmp_path / "journal.csv", "csv")
    assert "'=HYPERLINK(1)" in output.read_text()
    assert stat.S_IMODE(output.stat().st_mode) == 0o600
    with pytest.raises(FileExistsError):
        exports.write_export(rows, output, "csv")
    output = exports.write_export(rows, tmp_path / "journal.json")
    assert json.loads(output.read_text()) == rows


def test_migration_rejects_invalid_schema_without_connecting(legacy):
    with pytest.raises(ValueError, match="Invalid schema"):
        migration.migrate(
            migration.read_source(legacy[0]), "invalid", "public; DROP TABLE users"
        )
