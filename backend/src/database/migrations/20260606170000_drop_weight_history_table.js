/**
 * Ağırlık geçmişi vet_visits üzerinden okunur; ayrı tablo gereksiz kopya tutuyordu.
 *
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = async function (knex) {
  await knex.schema.dropTableIfExists("weight_history");
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = async function (knex) {
  await knex.schema.createTable("weight_history", (table) => {
    table.increments("weight_id").primary();
    table
      .integer("cat_id")
      .unsigned()
      .notNullable()
      .references("cat_id")
      .inTable("cats")
      .onDelete("CASCADE");
    table.decimal("weight", 5, 2).notNullable();
    table.date("recorded_date").notNullable();
    table.timestamps(true, true);
  });
};
