/**
 * Kullanıcı profili tek varsayılan görsel ile yönetileceği için avatar_gender kaldırıldı.
 *
 * @param { import("knex").Knex } knex
 */
exports.up = async function up(knex) {
  await knex.schema.alterTable("users", (table) => {
    table.dropColumn("avatar_gender");
  });
};

exports.down = async function down(knex) {
  await knex.schema.alterTable("users", (table) => {
    table.enu("avatar_gender", ["male", "female", "unspecified"]);
  });
};
