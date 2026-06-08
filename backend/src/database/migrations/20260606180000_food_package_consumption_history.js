/**
 * Tamamlanan mama paketlerinin tüketim geçmişi.
 *
 * @param { import("knex").Knex } knex
 */
exports.up = async function up(knex) {
  const exists = await knex.schema.hasTable("food_package_consumption_history");
  if (exists) return;

  await knex.schema.createTable("food_package_consumption_history", (table) => {
    table.increments("consumption_id").primary();
    table
      .integer("user_id")
      .unsigned()
      .notNullable()
      .references("user_id")
      .inTable("users")
      .onDelete("CASCADE");
    table.date("opening_date").notNullable();
    table.date("completion_date").notNullable();
    table.decimal("package_weight_kg", 6, 2).notNullable();
    table.decimal("daily_food_grams", 8, 2).notNullable();
    table.timestamp("created_at").defaultTo(knex.fn.now());

    table.index(["user_id", "opening_date"]);
  });
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = async function down(knex) {
  await knex.schema.dropTableIfExists("food_package_consumption_history");
};
