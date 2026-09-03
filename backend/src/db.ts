import {Connector, IpAddressTypes} from '@google-cloud/cloud-sql-connector';
import {Pool} from 'pg';

/**
 * Cloud SQL (PostgreSQL) connection pool.
 *
 * In production (deployed Cloud Function) we connect through the Cloud SQL
 * Node.js Connector, which uses the function's service account + IAM auth
 * proxying instead of exposing the database on a public IP. Locally
 * (emulator / `npm run shell`) we fall back to a plain connection string.
 *
 * Required config (Cloud Functions params / .env for local dev):
 *   INSTANCE_CONNECTION_NAME  e.g. "padelhub-prod:southamerica-east1:padelhub-sql"
 *   DB_USER, DB_PASSWORD, DB_NAME
 *   DATABASE_URL              local/dev override, e.g. postgres://user:pass@localhost:5432/padelhub
 */
let poolPromise: Promise<Pool> | null = null;

async function createPool(): Promise<Pool> {
  if (process.env.DATABASE_URL) {
    return new Pool({connectionString: process.env.DATABASE_URL, max: 5});
  }

  const instanceConnectionName = process.env.INSTANCE_CONNECTION_NAME;
  if (!instanceConnectionName) {
    throw new Error(
      'Missing INSTANCE_CONNECTION_NAME (or DATABASE_URL for local dev). ' +
        'Set it via `firebase functions:config:set` / Cloud Functions params.',
    );
  }

  const connector = new Connector();
  const clientOpts = await connector.getOptions({
    instanceConnectionName,
    ipType: IpAddressTypes.PRIVATE,
  });

  return new Pool({
    ...clientOpts,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME ?? 'padelhub',
    max: 5,
  });
}

export function getPool(): Promise<Pool> {
  if (!poolPromise) {
    poolPromise = createPool();
  }
  return poolPromise;
}
