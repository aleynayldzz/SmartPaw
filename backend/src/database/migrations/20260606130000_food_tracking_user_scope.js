/**
 * Mama takibi kullanıcı bazlıdır; bakım ekranında kedi seçimi yoktur.
 *
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = async function (knex) {
  const hasCatUnique = await knex.schema.hasTable("food_tracking").then(async (exists) => {
    if (!exists) return false;
    const result = await knex.raw(`
      SELECT 1
      FROM pg_constraint
      WHERE conrelid = 'food_tracking'::regclass
        AND contype = 'u'
        AND pg_get_constraintdef(oid) LIKE '%cat_id%'
      LIMIT 1
    `);
    return result.rows.length > 0;
  });

  if (hasCatUnique) {
    await knex.schema.alterTable("food_tracking", (table) => {
      table.dropUnique(["cat_id"]);
    });
  }

  await knex.schema.alterTable("food_tracking", (table) => {
    table
      .integer("user_id")
      .unsigned()
      .references("user_id")
      .inTable("users")
      .onDelete("CASCADE");
  });

  await knex.raw(`
    UPDATE food_tracking f
    SET user_id = c.user_id
    FROM cats c
    WHERE c.cat_id = f.cat_id
  `);

  await knex("food_tracking").whereNull("user_id").del();

  await knex.schema.alterTable("food_tracking", (table) => {
    table.dropForeign(["cat_id"]);
    table.dropColumn("cat_id");
  });

  await knex.schema.alterTable("food_tracking", (table) => {
    table.integer("user_id").unsigned().notNullable().alter();
    table.unique(["user_id"]);
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = async function (knex) {
  await knex.schema.alterTable("food_tracking", (table) => {
    table.dropUnique(["user_id"]);
    table.dropForeign(["user_id"]);
    table.dropColumn("user_id");
    table
      .integer("cat_id")
      .unsigned()
      .references("cat_id")
      .inTable("cats")
      .onDelete("CASCADE");
  });
};
