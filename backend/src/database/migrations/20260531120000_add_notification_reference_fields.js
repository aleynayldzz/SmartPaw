/**
 * Placeholder migration.
 *
 * This file exists to restore migration chain integrity for Knex.
 * The original migration file referenced in the database migration history
 * is missing from the repository, which makes `knex migrate:*` commands fail
 * with "migration directory is corrupt".
 *
 * IMPORTANT:
 * - This migration intentionally performs NO schema changes.
 * - Notification-related schema changes will be implemented later as planned.
 *
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = async function (_knex) {
  // no-op
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = async function (_knex) {
  // no-op
};

