/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function (knex) {
    return knex.schema.createTable('play_sessions', (table) => {
        // Primary Key: session_id
        table.increments('session_id').primary();

        // Foreign Key: cat_id (Kediler tablosuna bağlı)
        table.integer('cat_id')
            .unsigned()
            .notNullable()
            .references('cat_id')
            .inTable('cats')
            .onDelete('CASCADE');

        // Oyun Bilgileri
        table.date('play_date').notNullable(); // Oyunun gerçekleştiği tarih
        table.integer('duration_minutes');     // Oyun süresi (dakika)

        // Notlar (Örn: "Lazerle oynadı", "Favori oyuncağını getirdi")
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
    return knex.schema.dropTableIfExists('play_sessions');
};