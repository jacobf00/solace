import { Pool } from 'pg';

export const pgPool = new Pool({
  connectionString: process.env.DIRECT_DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' 
    ? { rejectUnauthorized: false } 
    : false,
  max: 10,
});

// Graceful shutdown
if (typeof process !== 'undefined') {
  process.on('SIGTERM', () => {
    pgPool.end();
  });
}
