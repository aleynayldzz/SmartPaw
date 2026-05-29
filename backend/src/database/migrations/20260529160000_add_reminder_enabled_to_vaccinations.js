/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = async function (knex) {
  const hasColumn = await knex.schema.hasColumn(
    "vaccinations",
    "reminder_enabled"
  );
  if (hasColumn) return;

  await knex.schema.alterTable("vaccinations", (table) => {
    table.boolean("reminder_enabled").notNullable().defaultTo(false);
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = async function (knex) {
  const hasColumn = await knex.schema.hasColumn(
    "vaccinations",
    "reminder_enabled"
  );
  if (!hasColumn) return;

  await knex.schema.alterTable("vaccinations", (table) => {
    table.dropColumn("reminder_enabled");
  });
};
