/**
 * Eski kedi bazlı günlük görev tablolarını kaldırır;
 * user_daily_routine_checks eski slot_index şemasındaysa task_key şemasına geçirir.
 * @param { import("knex").Knex } knex
 */
exports.up = async function (knex) {
  await knex.schema.dropTableIfExists("daily_task_completions");
  await knex.schema.dropTableIfExists("daily_tasks");

  const hasRoutine = await knex.schema.hasTable("user_daily_routine_checks");
  if (!hasRoutine) {
    return knex.schema.createTable("user_daily_routine_checks", (table) => {
      table
        .integer("user_id")
        .unsigned()
        .notNullable()
        .references("user_id")
        .inTable("users")
        .onDelete("CASCADE");
      table.date("check_date").notNullable();
      table.string("task_key", 32).notNullable();
      table.boolean("is_done").notNullable().defaultTo(false);
      table.timestamp("completed_at").nullable();
      table.timestamps(true, true);
      table.primary(["user_id", "check_date", "task_key"]);
      table.index(["user_id", "check_date"]);
    });
  }

  const hasSlotIndex = await knex.schema.hasColumn(
    "user_daily_routine_checks",
    "slot_index"
  );
  if (hasSlotIndex) {
    await knex.schema.dropTable("user_daily_routine_checks");
    return knex.schema.createTable("user_daily_routine_checks", (table) => {
      table
        .integer("user_id")
        .unsigned()
        .notNullable()
        .references("user_id")
        .inTable("users")
        .onDelete("CASCADE");
      table.date("check_date").notNullable();
      table.string("task_key", 32).notNullable();
      table.boolean("is_done").notNullable().defaultTo(false);
      table.timestamp("completed_at").nullable();
      table.timestamps(true, true);
      table.primary(["user_id", "check_date", "task_key"]);
      table.index(["user_id", "check_date"]);
    });
  }

  const hasCompletedAt = await knex.schema.hasColumn(
    "user_daily_routine_checks",
    "completed_at"
  );
  if (!hasCompletedAt) {
    await knex.schema.alterTable("user_daily_routine_checks", (table) => {
      table.timestamp("completed_at").nullable();
    });
  }
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = async function (knex) {
  // Geri alımda eski daily_tasks tabloları yeniden oluşturulmaz (bilinçli).
  const hasTaskKey = await knex.schema.hasColumn(
    "user_daily_routine_checks",
    "task_key"
  );
  if (hasTaskKey) {
    await knex.schema.dropTableIfExists("user_daily_routine_checks");
  }
};
