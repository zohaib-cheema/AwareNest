const fs = require('node:fs/promises');
const path = require('node:path');
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const cookieParser = require('cookie-parser');
const helmet = require('helmet');

async function initialize(pool) {
  await pool.query(await fs.readFile(path.join(__dirname, 'sql/001_init.sql'), 'utf8'));
}

function createApp(pool, { secret, production = false, origins = [] }) {
  if (!secret || Buffer.byteLength(secret) < 32)
    throw new Error('A strong session secret is required');
  const app = express();
  app.disable('x-powered-by');
  app.use(
    helmet({
      contentSecurityPolicy: {
        directives: {
          defaultSrc: ["'self'"],
          scriptSrc: ["'self'"],
          styleSrc: ["'self'"],
          imgSrc: ["'self'", 'data:'],
          connectSrc: ["'self'"],
          upgradeInsecureRequests: production ? [] : null,
        },
      },
    }),
  );
  app.use(express.json({ limit: '12kb' }));
  app.use(cookieParser());
  app.use((req, res, next) => {
    if (req.path.startsWith('/api/') || ['/login', '/signup', '/protected'].includes(req.path))
      res.set('Cache-Control', 'no-store');
    if (
      !['GET', 'HEAD', 'OPTIONS'].includes(req.method) &&
      req.headers.origin &&
      !origins.includes(req.headers.origin)
    ) {
      return res.status(403).json({ message: 'This origin is not allowed' });
    }
    next();
  });
  const cookieOptions = { httpOnly: true, secure: production, sameSite: 'strict', path: '/' };
  const attempts = new Map();
  const limit = (req, res, next) => {
    const now = Date.now();
    for (const [key, value] of attempts) if (value.until <= now) attempts.delete(key);
    const key = req.ip;
    const bucket = attempts.get(key) || { count: 0, until: now + 15 * 60 * 1000 };
    if (bucket.count >= 30) {
      res.set('Retry-After', String(Math.ceil((bucket.until - now) / 1000)));
      return res.status(429).json({ message: 'Too many attempts. Please try again later.' });
    }
    bucket.count += 1;
    attempts.set(key, bucket);
    next();
  };
  function authenticate(req, res, next) {
    const header = req.headers.authorization;
    const token = header ? header.replace(/^Bearer\s+/i, '') : req.cookies.session;
    if (!token) return res.status(401).json({ message: 'Please sign in' });
    try {
      const decoded = jwt.verify(token, secret, { algorithms: ['HS256'], issuer: 'awarenest' });
      const userId = Number(decoded.sub);
      if (!Number.isSafeInteger(userId) || userId <= 0) throw new Error('Invalid subject');
      req.userId = userId;
      next();
    } catch {
      res.clearCookie('session', cookieOptions);
      return res.status(401).json({ message: 'Your session has expired. Please sign in again.' });
    }
  }
  const signup = async (req, res) => {
    const { username, password, email, phone = '' } = req.body || {};
    if (
      typeof username !== 'string' ||
      username.trim().length < 3 ||
      username.trim().length > 40 ||
      typeof password !== 'string' ||
      password.length < 10 ||
      Buffer.byteLength(password) > 72 ||
      typeof email !== 'string' ||
      email.length > 254 ||
      !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) ||
      typeof phone !== 'string' ||
      phone.length > 40
    ) {
      return res.status(400).json({
        message:
          'Use a name with 3 to 40 characters, a valid email, and a password with 10 or more characters and at most 72 bytes.',
      });
    }
    const hash = await bcrypt.hash(password, 12);
    try {
      await pool.query(
        'INSERT INTO users (username, password, email, phone) VALUES ($1, $2, $3, $4)',
        [username.trim(), hash, email.trim().toLowerCase(), phone.trim()],
      );
    } catch (error) {
      if (error.code === '23505')
        return res.status(409).json({ message: 'That name or email is already registered' });
      throw error;
    }
    res.status(201).json({ message: 'Account created' });
  };
  const login = async (req, res) => {
    const { username, password } = req.body || {};
    if (
      typeof username !== 'string' ||
      typeof password !== 'string' ||
      username.length > 40 ||
      Buffer.byteLength(password) > 72
    ) {
      return res.status(400).json({ message: 'Enter your name and password' });
    }
    const { rows } = await pool.query(
      'SELECT id, username, password FROM users WHERE lower(username) = lower($1)',
      [username.trim()],
    );
    const user = rows[0];
    const hash = user?.password || '$2b$12$RBmHH0DkKVAVR0mcjCDZf.1Vxc/9Xq8YbXZrvMXclbB3J5kQ3fZZS';
    if (!(await bcrypt.compare(password, hash)) || !user)
      return res.status(401).json({ message: 'The name or password is incorrect' });
    const token = jwt.sign({ userId: user.id, username: user.username }, secret, {
      algorithm: 'HS256',
      issuer: 'awarenest',
      subject: String(user.id),
      expiresIn: '1h',
    });
    res.cookie('session', token, { ...cookieOptions, maxAge: 60 * 60 * 1000 });
    res.json({ token, user: { id: user.id, username: user.username } });
  };
  app.post(['/signup', '/api/signup'], limit, signup);
  app.post(['/login', '/api/login'], limit, login);
  app.post('/api/logout', (req, res) => {
    res.clearCookie('session', cookieOptions);
    res.sendStatus(204);
  });
  app.get('/protected', authenticate, (req, res) => res.json({ message: 'You are authorized' }));
  app.get('/api/me', authenticate, async (req, res) => {
    const { rows } = await pool.query('SELECT id, username FROM users WHERE id = $1', [req.userId]);
    if (!rows.length) return res.status(401).json({ message: 'Please sign in again' });
    res.json({ user: rows[0] });
  });
  app.get('/api/checkins', authenticate, async (req, res) => {
    const mood = req.query.mood === undefined ? null : Number(req.query.mood);
    const before = req.query.before === undefined ? null : Number(req.query.before);
    if (
      (mood !== null && (!Number.isInteger(mood) || mood < 1 || mood > 5)) ||
      (before !== null && (!Number.isSafeInteger(before) || before <= 0))
    ) {
      return res.status(400).json({ message: 'Invalid journal filter' });
    }
    const { rows } = await pool.query(
      `SELECT id, mood, note, created_at FROM checkins
      WHERE user_id = $1 AND ($2::int IS NULL OR mood = $2)
      AND ($3::int IS NULL OR id < $3) ORDER BY id DESC LIMIT 51`,
      [req.userId, mood, before],
    );
    const entries = rows.slice(0, 50);
    res.json({ entries, next: rows.length > 50 ? entries.at(-1).id : null });
  });
  app.post('/api/checkins', authenticate, async (req, res) => {
    const { mood, note = '' } = req.body || {};
    if (
      !Number.isInteger(mood) ||
      mood < 1 ||
      mood > 5 ||
      typeof note !== 'string' ||
      note.length > 2000
    ) {
      return res
        .status(400)
        .json({ message: 'Choose a mood from 1 to 5 and keep notes within 2000 characters' });
    }
    const { rows } = await pool.query(
      'INSERT INTO checkins (user_id, mood, note) VALUES ($1, $2, $3) RETURNING id, mood, note, created_at',
      [req.userId, mood, note.trim()],
    );
    res.status(201).json({ entry: rows[0] });
  });
  app.delete('/api/checkins/:id', authenticate, async (req, res) => {
    const id = Number(req.params.id);
    if (!Number.isSafeInteger(id) || id <= 0)
      return res.status(400).json({ message: 'Invalid entry' });
    const { rowCount } = await pool.query('DELETE FROM checkins WHERE id = $1 AND user_id = $2', [
      id,
      req.userId,
    ]);
    if (!rowCount) return res.status(404).json({ message: 'Entry not found' });
    res.sendStatus(204);
  });
  app.get('/api/weekly', authenticate, async (req, res) => {
    const timezone = req.query.timezone || 'UTC';
    try {
      new Intl.DateTimeFormat('en', { timeZone: timezone });
    } catch {
      return res.status(400).json({ message: 'Invalid time zone' });
    }
    const { rows } = await pool.query(
      `WITH days AS (
      SELECT generate_series((CURRENT_TIMESTAMP AT TIME ZONE $2)::date - 6,
        (CURRENT_TIMESTAMP AT TIME ZONE $2)::date, INTERVAL '1 day')::date AS day
      ) SELECT to_char(days.day, 'YYYY-MM-DD') AS day,
        ROUND(AVG(c.mood), 2)::float AS average, COUNT(c.id)::int AS count
      FROM days LEFT JOIN checkins c ON c.user_id = $1
        AND (c.created_at AT TIME ZONE $2)::date = days.day
        AND c.created_at >= CURRENT_TIMESTAMP - INTERVAL '8 days'
      GROUP BY days.day ORDER BY days.day`,
      [req.userId, timezone],
    );
    res.json({ days: rows, timezone });
  });
  app.get('/api/health', async (req, res) => {
    try {
      await pool.query('SELECT 1');
      res.json({ status: 'ready' });
    } catch {
      res.status(503).json({ status: 'unavailable' });
    }
  });
  app.use('/api', (req, res) => res.status(404).json({ message: 'Endpoint not found' }));
  app.use(express.static(path.join(__dirname, '../web/dist')));
  app.use((error, req, res, next) => {
    if (error.type === 'entity.too.large')
      return res.status(413).json({ message: 'The request is too large' });
    if (error.type === 'entity.parse.failed')
      return res.status(400).json({ message: 'Invalid JSON' });
    console.error('Request failed', error.code || error.name);
    res.status(500).json({ message: 'Something went wrong. Please try again.' });
  });
  return app;
}
module.exports = { createApp, initialize };
