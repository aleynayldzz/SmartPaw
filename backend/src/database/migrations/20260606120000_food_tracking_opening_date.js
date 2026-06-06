/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = async function (knex) {
  await knex.schema.alterTable("food_tracking", (table) => {
    table.date("opening_date");
  });

  await knex("food_tracking")
    .whereNull("opening_date")
    .update({
      opening_date: knex.raw("COALESCE(last_updated, created_at::date)")
    });

  await knex.schema.alterTable("food_tracking", (table) => {
    table.date("opening_date").notNullable().alter();
    table.decimal("daily_food_grams", 8, 2).notNullable().alter();
    table.decimal("package_weight_kg", 8, 2).notNullable().alter();
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = async function (knex) {
  await knex.schema.alterTable("food_tracking", (table) => {
    table.dropColumn("opening_date");
    table.decimal("daily_food_grams", 8, 2).nullable().alter();
    table.decimal("package_weight_kg", 8, 2).nullable().alter();
  });
};
