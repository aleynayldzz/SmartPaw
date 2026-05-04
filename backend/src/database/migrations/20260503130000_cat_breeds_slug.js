/**
 * Mobil ve API için sabit ırk anahtarı; seed ile doldurulur.
 *
 * @param { import("knex").Knex } knex
 */
exports.up = async function up(knex) {
  await knex.schema.alterTable("cat_breeds", (table) => {
    table.string("slug", 128).nullable().unique();
  });
};

exports.down = async function down(knex) {
  await knex.schema.alterTable("cat_breeds", (table) => {
    table.dropColumn("slug");
  });
};
