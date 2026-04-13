/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function (knex) {
    return knex.schema.createTable('litter_tracking', (table) => {
        // Primary Key: litter_id
        table.increments('litter_id').primary();

        // Foreign Key: cat_id (Kediler tablosuna bağlı)
        table.integer('cat_id')
            .unsigned()
            .notNullable()
            .references('cat_id')
            .inTable('cats')
            .onDelete('CASCADE');

        // Tarih Alanları
        table.date('last_cleaning_date');      // Son temizleme tarihi
        table.date('last_full_change_date');   // Son tam değişim tarihi

        // Frekans Alanları (Kaç günde bir yapılacağı)
        table.integer('cleaning_frequency_days'); // Temizlik sıklığı (gün)
        table.integer('change_frequency_days');   // Değişim sıklığı (gün)

        // Gelecek Tarih Tahminleri
        table.date('next_cleaning_date');      // Bir sonraki temizleme tarihi
        table.date('next_change_date');        // Bir sonraki tam değişim tarihi

        // Zaman damgaları
        table.timestamps(true, true);
    });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function (knex) {
    return knex.schema.dropTableIfExists('litter_tracking');
};