/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = async function (knex) {
  // 1) Add nullable column first (safe for existing rows)
  await knex.schema.alterTable("vet_visits", (table) => {
    table.decimal("weight", 5, 2).nullable();
  });

  // 2) Backfill: if any legacy visit exists, copy cat weight if present, else 0
  await knex.raw(`
    UPDATE vet_visits vv
    SET weight = COALESCE(vv.weight, c.weight, 0)
    FROM cats c
    WHERE vv.cat_id = c.cat_id
  `);

  // 3) Ensure no null remains (covers rows that didn't match join for any reason)
  await knex("vet_visits").whereNull("weight").update({ weight: 0 });

  // 4) Enforce NOT NULL going forward
  await knex.schema.alterTable("vet_visits", (table) => {
    table.decimal("weight", 5, 2).notNullable().alter();
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = async function (knex) {
  await knex.schema.alterTable("vet_visits", (table) => {
    table.dropColumn("weight");
  });
};

