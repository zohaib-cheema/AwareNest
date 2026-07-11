# AwareNest

A private mood journal with a React and TypeScript companion dashboard, a Node.js API, and PostgreSQL storage. The repository also contains the original Flutter mobile prototype and Python tools for migration and journal exports.

![Companion web journal with sample entries](docs/journal.png)

## Use the web journal locally

Requirements: Node.js 22.13 or newer, Python 3.11 or newer, and Docker with Compose.

```bash
python3 ops/configure_local.py
docker compose up -d
npm ci
npm ci --prefix web
npm run dev:api
```

In another terminal:

```bash
npm run dev:web
```

Open `http://127.0.0.1:5173`. Create an account, choose a mood, and save an optional note. The private `.env` file contains freshly generated local credentials. It is ignored by Git and is never overwritten by the configuration tool.

The default Compose database port is 55432. Production deployments should set `DATABASE_URL`, a random `JWT_SECRET` with at least 32 bytes, `WEB_ORIGIN`, and `NODE_ENV=production`, then use HTTPS through a reverse proxy. The API binds to loopback by default.

## Journal behavior

1. Accounts use bcrypt password hashes. The web session uses an HttpOnly cookie. Existing `/signup`, `/login`, and `/protected` routes remain available for the Flutter client, including bearer token authorization after signing in again.
2. Each account can read and delete only its own check ins. Input validation, parameterized SQL, origin checks, and a basic authentication attempt limit are included.
3. The weekly chart uses daily averages in the browser's time zone. Days without an entry remain empty. Recent entries support mood filtering and pagination.
4. Check ins persist in PostgreSQL and remain available after signing out and back in. Deletion asks for confirmation in the interface.

This is a journal for reflection. It does not diagnose conditions or provide medical advice.

## Architecture

`web/` contains the React and TypeScript interface. `backend/` contains the Express API and PostgreSQL schema. `ops/` contains Python configuration, migration, export, and deployment checks. `lib/` and the platform folders contain the Flutter prototype. Its C++ files include the Flutter desktop runner.

The companion journal and Flutter prototype have separate screens. The journal API preserves the existing authentication route names; full journal integration into the mobile screens is a future change.

## Migrate a legacy SQLite account database

The old database file is no longer tracked. Keep a private copy before upgrading. Install the Python migration dependency in a virtual environment, then check the source first:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r ops/requirements.txt
python ops/migrate_sqlite.py /path/to/private/legacy.db
```

To import into an empty PostgreSQL users table, set `DATABASE_URL` in the shell and run the same command with `--apply`. The source is read only. IDs and bcrypt hashes are preserved. Duplicate names, duplicate email addresses, and unsupported password formats stop the migration. Repeating the same completed snapshot is safe.

Use the migration before creating new accounts in the target. A newly imported snapshot is refused if the target already has accounts.

```bash
python ops/verify_schema.py
python ops/export_journal.py --user-id ACCOUNT_ID --output private_journal.json
```

Exports are private files and refuse to overwrite an existing path. CSV exports neutralize spreadsheet formulas in notes.

## Build and verify

```bash
npm run build
TEST_DATABASE_URL=postgresql://USER:PASSWORD@127.0.0.1:55432/awarenest npm test
TEST_DATABASE_URL=postgresql://USER:PASSWORD@127.0.0.1:55432/awarenest pytest ops/tests -q
```

The tests create isolated PostgreSQL schemas and clean them up afterward. CI checks the web build, account isolation, journal persistence, validation, pagination, migration integrity, and export behavior. Desktop and mobile browser verification is documented in `docs/verification.md`.

For the original mobile prototype, install Flutter, run `flutter pub get`, and configure your own Firebase project before launching. The existing mobile prototype was not rebuilt as part of the companion journal change.
