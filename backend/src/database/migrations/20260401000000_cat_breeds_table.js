/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function (knex) {
    return knex.schema.createTable('cat_breeds', (table) => {
        // Primary Key: breed_id
        table.increments('breed_id').primary();

        // Varchar alanlar
        table.string('breed_name').notNullable().unique(); // Aynı ırk ismi tekrar etmesin
        table.string('avatar_url').nullable(); // Irkı temsil eden bir görsel linki

        // Zaman damgaları (Opsiyonel ama iyi pratiktir)
        table.timestamps(true, true);
    });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function (knex) {
    return knex.schema.dropTableIfExists('cat_breeds');
};