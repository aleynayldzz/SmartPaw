/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function (knex) {
    return knex.schema.createTable('health_records', (table) => {
        // Primary Key
        table.increments('record_id').primary();

        // Foreign Key: Hangi kediye ait sağlık kaydı?
        table.integer('cat_id')
            .unsigned()
            .notNullable()
            .references('cat_id')
            .inTable('cats')
            .onDelete('CASCADE');

        // Kayıt Bilgileri
        table.date('record_date').notNullable(); // Kaydın tutulduğu veya olayın yaşandığı tarih
        table.string('condition_type');          // Durum tipi (Örn: Alerji, Ameliyat, Genel Kontrol)

        // Detaylar
        table.text('description');               // Durumun detaylı açıklaması
        table.boolean('is_chronic').defaultTo(false); // Bu durum kronik mi? (Örn: Astım)

        // Zaman Damgaları (Diyagramdaki created_at ve updated_at)
        table.timestamps(true, true);
    });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function (knex) {
    return knex.schema.dropTableIfExists('health_records');
};