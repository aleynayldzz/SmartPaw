/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function (knex) {
    return knex.schema.createTable('medications', (table) => {
        // Primary Key
        table.increments('medication_id').primary();

        // Foreign Key: Hangi kedi bu ilacı kullanıyor?
        table.integer('cat_id')
            .unsigned()
            .notNullable()
            .references('cat_id')
            .inTable('cats')
            .onDelete('CASCADE');

        // İlaç Detayları
        table.string('medication_name').notNullable(); // İlaç adı
        table.string('dosage');                        // Dozaj (Örn: "5ml", "1 tablet")
        table.string('frequency');                     // Sıklık (Örn: "Günde 2 kez")

        // Tarih Takibi
        table.date('start_date');                      // Başlangıç tarihi
        table.date('end_date');                        // Bitiş tarihi

        // Durum ve Notlar
        table.boolean('is_active').defaultTo(true);    // İlaç kullanımı devam ediyor mu?
        table.text('notes');                           // Ek notlar

        // Zaman Damgaları (created_at ve updated_at)
        table.timestamps(true, true);
    });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function (knex) {
    return knex.schema.dropTableIfExists('medications');
};