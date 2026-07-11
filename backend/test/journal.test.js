const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { randomBytes } = require('node:crypto');
const { Pool } = require('pg');
const { createApp, initialize } = require('../app');

let pool, admin, server, url, alice, bob, cookie;
const schema = `test_${randomBytes(6).toString('hex')}`;
const origin = 'http://127.0.0.1:5173';
async function call(path, { token, ...options } = {}) {
  const result = await fetch(url + path, {
    ...options,
    headers: {
      ...(options.body ? { 'Content-Type': 'application/json' } : {}),
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
  });
  const data = result.status === 204 ? null : await result.json();
  return { status: result.status, data, headers: result.headers };
}
async function account(username) {
  const signup = await call('/signup', {
    method: 'POST',
    body: JSON.stringify({
      username,
      password: 'a safe test password',
      email: `${username}@example.com`,
    }),
  });
  assert.equal(signup.status, 201);
  const login = await call('/login', {
    method: 'POST',
    body: JSON.stringify({ username, password: 'a safe test password' }),
  });
  assert.equal(login.status, 200);
  return login;
}
before(async () => {
  if (!process.env.TEST_DATABASE_URL)
    throw new Error('Set TEST_DATABASE_URL to run PostgreSQL integration tests');
  admin = new Pool({ connectionString: process.env.TEST_DATABASE_URL });
  await admin.query(`CREATE SCHEMA ${schema}`);
  pool = new Pool({
    connectionString: process.env.TEST_DATABASE_URL,
    options: `-c search_path=${schema}`,
  });
  await initialize(pool);
  server = createApp(pool, { secret: randomBytes(32).toString('hex'), origins: [origin] }).listen(
    0,
    '127.0.0.1',
  );
  await new Promise((resolve) => server.once('listening', resolve));
  url = `http://127.0.0.1:${server.address().port}`;
  const first = await account('alice');
  alice = first.data.token;
  cookie = first.headers.get('set-cookie');
  bob = (await account('bob')).data.token;
});
after(async () => {
  if (server) await new Promise((resolve) => server.close(resolve));
  if (pool) await pool.end();
  if (admin) {
    await admin.query(`DROP SCHEMA ${schema} CASCADE`);
    await admin.end();
  }
});
test('session uses an HttpOnly cookie and Flutter bearer authorization works', async () => {
  assert.match(cookie, /HttpOnly/);
  assert.match(cookie, /SameSite=Strict/);
  assert.equal((await call('/protected', { token: alice })).status, 200);
  assert.equal(
    (await call('/api/me', { headers: { Cookie: cookie.split(';')[0] } })).data.user.username,
    'alice',
  );
  assert.equal((await call('/api/checkins')).status, 401);
  assert.equal((await call('/api/checkins', { token: 'broken' })).status, 401);
});
test('journal entries belong to one account and persist in PostgreSQL', async () => {
  const saved = await call('/api/checkins', {
    token: alice,
    method: 'POST',
    body: JSON.stringify({ mood: 4, note: 'A short walk helped.' }),
  });
  assert.equal(saved.status, 201);
  const id = saved.data.entry.id;
  assert.equal((await call('/api/checkins', { token: bob })).data.entries.length, 0);
  assert.equal((await call(`/api/checkins/${id}`, { token: bob, method: 'DELETE' })).status, 404);
  assert.equal(
    (await pool.query('SELECT note FROM checkins WHERE id=$1', [id])).rows[0].note,
    'A short walk helped.',
  );
  assert.equal((await call('/api/checkins?mood=3', { token: alice })).data.entries.length, 0);
  assert.equal((await call('/api/checkins?mood=4', { token: alice })).data.entries.length, 1);
  assert.equal((await call(`/api/checkins/${id}`, { token: alice, method: 'DELETE' })).status, 204);
  assert.equal((await call('/api/checkins', { token: alice })).data.entries.length, 0);
});
test('weekly results keep missing days empty and average multiple check ins', async () => {
  for (const mood of [2, 4])
    await call('/api/checkins', { token: alice, method: 'POST', body: JSON.stringify({ mood }) });
  const result = await call('/api/weekly?timezone=America%2FNew_York', { token: alice });
  assert.equal(result.status, 200);
  assert.equal(result.data.days.length, 7);
  assert.equal(result.data.days.at(-1).average, 3);
  assert.equal(result.data.days.at(-1).count, 2);
  assert.equal(result.data.days[0].average, null);
  assert.equal(result.data.days[0].count, 0);
  assert.equal((await call('/api/weekly?timezone=invalid', { token: alice })).status, 400);
});
test('invalid inputs, SQL strings and foreign browser origins are rejected', async () => {
  for (const body of [{ mood: 6 }, { mood: '4' }, { mood: 1, note: 'x'.repeat(2001) }]) {
    assert.equal(
      (await call('/api/checkins', { token: alice, method: 'POST', body: JSON.stringify(body) }))
        .status,
      400,
    );
  }
  assert.equal((await call('/api/checkins?mood=1%20OR%201=1', { token: alice })).status, 400);
  assert.equal(
    (
      await call('/api/checkins', {
        token: alice,
        method: 'POST',
        headers: { Origin: 'https://another.example' },
        body: JSON.stringify({ mood: 3 }),
      })
    ).status,
    403,
  );
  assert.equal(
    (
      await call('/login', {
        method: 'POST',
        body: JSON.stringify({ username: "' OR 1=1 --", password: 'anything' }),
      })
    ).status,
    401,
  );
  assert.equal(
    (
      await call('/signup', {
        method: 'POST',
        body: JSON.stringify({
          username: 'alice',
          password: 'a safe test password',
          email: 'other@example.com',
        }),
      })
    ).status,
    409,
  );
});
test('pagination does not duplicate entries and preserves mood filtering', async () => {
  const user = (await pool.query("SELECT id FROM users WHERE username='bob'")).rows[0].id;
  await pool.query(
    "INSERT INTO checkins(user_id,mood,note) SELECT $1, 5, 'Page test' FROM generate_series(1,55)",
    [user],
  );
  const first = await call('/api/checkins?mood=5', { token: bob });
  assert.equal(first.data.entries.length, 50);
  assert.ok(first.data.next);
  const second = await call(`/api/checkins?mood=5&before=${first.data.next}`, { token: bob });
  assert.equal(second.data.entries.length, 5);
  assert.equal(second.data.next, null);
  assert.equal(
    new Set([...first.data.entries, ...second.data.entries].map((row) => row.id)).size,
    55,
  );
});
test('sign out clears the browser cookie', async () => {
  const result = await call('/api/logout', {
    method: 'POST',
    headers: { Origin: origin, Cookie: cookie.split(';')[0] },
  });
  assert.equal(result.status, 204);
  assert.match(result.headers.get('set-cookie'), /Expires=Thu, 01 Jan 1970/);
});
