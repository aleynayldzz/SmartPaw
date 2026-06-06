/**
 * Kum takibi kullanıcı bazlıdır; bakım ekranında kedi seçimi yoktur.
 *
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = async function (knex) {
  await knex.schema.alterTable("litter_tracking", (table) => {
    table
      .integer("user_id")
      .unsigned()
      .references("user_id")
      .inTable("users")
      .onDelete("CASCADE");
    table.integer("frequency_days");
  });

  await knex.raw(`
    UPDATE litter_tracking l
    SET user_id = c.user_id
    FROM cats c
    WHERE c.cat_id = l.cat_id
  `);

  await knex.raw(`
    UPDATE litter_tracking
    SET last_cleaning_date = COALESCE(last_full_change_date, last_cleaning_date)
    WHERE last_cleaning_date IS NULL OR last_full_change_date IS NOT NULL
  `);

  await knex.raw(`
    UPDATE litter_tracking
    SET frequency_days = COALESCE(change_frequency_days, cleaning_frequency_days)
    WHERE frequency_days IS NULL
  `);

  await knex("litter_tracking")
    .whereNull("user_id")
    .orWhereNull("last_cleaning_date")
    .orWhereNull("frequency_days")
    .del();

  await knex.schema.alterTable("litter_tracking", (table) => {
    table.dropForeign(["cat_id"]);
    table.dropColumn("cat_id");
    table.dropColumn("last_full_change_date");
    table.dropColumn("cleaning_frequency_days");
    table.dropColumn("change_frequency_days");
    table.dropColumn("next_cleaning_date");
    table.dropColumn("next_change_date");
  });

  await knex.schema.alterTable("litter_tracking", (table) => {
    table.integer("user_id").unsigned().notNullable().alter();
    table.date("last_cleaning_date").notNullable().alter();
    table.integer("frequency_days").notNullable().alter();
    table.unique(["user_id"]);
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = async function (knex) {
  await knex.schema.alterTable("litter_tracking", (table) => {
    table.dropUnique(["user_id"]);
    table.dropForeign(["user_id"]);
    table.dropColumn("user_id");
    table.dropColumn("frequency_days");
    table
      .integer("cat_id")
      .unsigned()
      .references("cat_id")
      .inTable("cats")
      .onDelete("CASCADE");
    table.date("last_full_change_date");
    table.integer("cleaning_frequency_days");
    table.integer("change_frequency_days");
    table.date("next_cleaning_date");
    table.date("next_change_date");
    table.date("last_cleaning_date").nullable().alter();
  });
};
