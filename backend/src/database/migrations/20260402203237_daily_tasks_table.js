/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function (knex) {
    return knex.schema.createTable('daily_tasks', (table) => {
        // Primary Key
        table.increments('task_id').primary();

        // Görev Adı (Örn: Sabah Maması)
        table.string('task_name').notNullable();

        // Açıklama (Uzun metinler için text kullanımı uygundur)
        table.text('description').nullable();

        // İkon (Frontend'de gösterilecek ikonun adı veya URL'i)
        table.string('icon').nullable();

        // Zaman damgaları
        table.timestamps(true, true);
    });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function (knex) {
    return knex.schema.dropTableIfExists('daily_tasks');
};