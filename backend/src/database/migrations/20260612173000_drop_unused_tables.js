/**
 * Kullanilmayan ve uygulama kodunda referans edilmeyen tabloları kaldırır.
 * notifications bilincli olarak korunur; bildirim ozelligi eklendiginde kullanilacak.
 *
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = async function (knex) {
  await knex.schema.dropTableIfExists("medication_schedules");
  await knex.schema.dropTableIfExists("play_sessions");
  await knex.schema.dropTableIfExists("grooming_records");
  await knex.schema.dropTableIfExists("health_records");
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = async function (knex) {
  const hasMedications = await knex.schema.hasTable("medications");
  if (hasMedications) {
    await knex.schema.createTable("medication_schedules", (table) => {
      table.increments("schedule_id").primary();
      table
        .integer("medication_id")
        .unsigned()
        .notNullable()
        .references("medication_id")
        .inTable("medications")
        .onDelete("CASCADE");
      table.time("reminder_time").notNullable();
      table.boolean("is_active").defaultTo(true);
      table.timestamps(true, true);
    });
  }

  const hasCats = await knex.schema.hasTable("cats");
  if (!hasCats) {
    return;
  }

  await knex.schema.createTable("play_sessions", (table) => {
    table.increments("session_id").primary();
    table
      .integer("cat_id")
      .unsigned()
      .notNullable()
      .references("cat_id")
      .inTable("cats")
      .onDelete("CASCADE");
    table.date("play_date").notNullable();
    table.integer("duration_minutes");
    table.text("notes").nullable();
    table.timestamps(true, true);
  });

  await knex.schema.createTable("grooming_records", (table) => {
    table.increments("grooming_id").primary();
    table
      .integer("cat_id")
      .unsigned()
      .notNullable()
      .references("cat_id")
      .inTable("cats")
      .onDelete("CASCADE");
    table
      .enu("grooming_type", ["brushing", "nail_trimming", "ear_cleaning", "eat_malt", "other"])
      .defaultTo("brushing");
    table.date("grooming_date").notNullable();
    table.text("notes").nullable();
    table.timestamps(true, true);
  });

  await knex.schema.createTable("health_records", (table) => {
    table.increments("record_id").primary();
    table
      .integer("cat_id")
      .unsigned()
      .notNullable()
      .references("cat_id")
      .inTable("cats")
      .onDelete("CASCADE");
    table.date("record_date").notNullable();
    table.string("condition_type");
    table.text("description");
    table.boolean("is_chronic").defaultTo(false);
    table.timestamps(true, true);
  });
};
