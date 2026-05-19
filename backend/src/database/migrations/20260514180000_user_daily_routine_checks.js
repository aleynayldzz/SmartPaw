/**
 * Kullanıcı günlük rutin işaretleri (kullanıcı + gün + task_key).
 * @param { import("knex").Knex } knex
 */
exports.up = function (knex) {
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
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = function (knex) {
  return knex.schema.dropTableIfExists("user_daily_routine_checks");
};
