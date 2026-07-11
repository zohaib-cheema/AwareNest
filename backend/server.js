const { Pool } = require('pg');
const { createApp, initialize } = require('./app');

async function start() {
  const { DATABASE_URL, JWT_SECRET, PORT = '3000', NODE_ENV, WEB_ORIGIN } = process.env;
  if (!DATABASE_URL || !JWT_SECRET || Buffer.byteLength(JWT_SECRET) < 32) {
    throw new Error('Set DATABASE_URL and a JWT_SECRET with at least 32 bytes');
  }
  const pool = new Pool({ connectionString: DATABASE_URL, max: 10 });
  pool.on('error', () => console.error('Unexpected database connection error'));
  await initialize(pool);
  const app = createApp(pool, {
    secret: JWT_SECRET,
    production: NODE_ENV === 'production',
    origins: (
      WEB_ORIGIN ||
      'http://127.0.0.1:5173,http://localhost:5173,http://127.0.0.1:3000,http://localhost:3000'
    ).split(','),
  });
  const server = app.listen(Number(PORT), '127.0.0.1', () =>
    console.log(`AwareNest is ready on http://127.0.0.1:${PORT}`),
  );
  for (const signal of ['SIGTERM', 'SIGINT'])
    process.once(signal, () => {
      server.close(async () => {
        await pool.end();
        process.exit(0);
      });
      setTimeout(() => process.exit(1), 10000).unref();
    });
}
start().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
