/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function (knex) {
    return knex.schema.createTable('grooming_records', (table) => {
        // Primary Key
        table.increments('grooming_id').primary();

        // Foreign Key: Hangi kedi için bakım yapıldı?
        table.integer('cat_id')
            .unsigned()
            .notNullable()
            .references('cat_id')
            .inTable('cats')
            .onDelete('CASCADE');

        // Bakım Tipi (Enum yapısı ile standartlaştırıyoruz)
        table.enu('grooming_type', ['brushing', 'nail_trimming', 'ear_cleaning', 'eat_malt', 'other'])
            .defaultTo('brushing');

        // Tarih ve Notlar
        table.date('grooming_date').notNullable();
        table.text('notes').nullable();

        // Zaman Damgaları (created_at ve updated_at)
        table.timestamps(true, true);
    });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function (knex) {
    return knex.schema.dropTableIfExists('grooming_records');
};