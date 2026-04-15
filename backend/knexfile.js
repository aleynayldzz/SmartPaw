// Update with your config settings.
const path = require("node:path");

// Ensure env vars are available when running knex CLI (migrations only)
require("dotenv").config({ path: path.resolve(process.cwd(), ".env") });

/**
 * @type { Object.<string, import("knex").Knex.Config> }
 */
module.exports = {
  development: {
    client: "pg",
    connection: {
      host: process.env.DB_HOST,
      port: Number(process.env.DB_PORT),
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_DATABASE
    },
    migrations: {
      directory: "./src/database/migrations"
    }
  }
};