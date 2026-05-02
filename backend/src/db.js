const path = require("node:path");
const dotenv = require("dotenv");
const { Pool } = require("pg");
const { isNonEmptyString } = require("./utils/validators");

dotenv.config({ path: path.resolve(process.cwd(), ".env") });

const hasDbConfig =
  isNonEmptyString(process.env.DB_HOST) &&
  isNonEmptyString(process.env.DB_PORT) &&
  isNonEmptyString(process.env.DB_USER) &&
  isNonEmptyString(process.env.DB_PASSWORD) &&
  isNonEmptyString(process.env.DB_DATABASE);

const pool = hasDbConfig
  ? new Pool({
      host: process.env.DB_HOST,
      port: Number(process.env.DB_PORT),
      user: process.env.DB_USER,
      password: String(process.env.DB_PASSWORD),
      database: process.env.DB_DATABASE
    })
  : null;

if (!pool) {
  console.warn(
    "Database is not configured. Create backend/.env with DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_DATABASE."
  );
}

module.exports = {
  pool,
  hasDbConfig,
  dbNotConfiguredPayload: () => ({
    ok: false,
    message:
      "Database is not configured. Please create backend/.env and set DB_* variables."
  })
};
