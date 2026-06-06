/**
 * Kalan mama ve bitiş tarihi okuma anında hesaplanır; DB'de tutulmaz.
 *
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = async function (knex) {
  await knex.schema.alterTable("food_tracking", (table) => {
    table.dropColumn("remaining_weight_kg");
    table.dropColumn("last_updated");
    table.dropColumn("estimated_finish_date");
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = async function (knex) {
  await knex.schema.alterTable("food_tracking", (table) => {
    table.decimal("remaining_weight_kg", 8, 2);
    table.date("last_updated");
    table.date("estimated_finish_date");
  });
};
