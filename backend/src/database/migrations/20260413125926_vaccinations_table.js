/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function (knex) {
    return knex.schema.createTable('vaccinations', (table) => {
        // Primary Key
        table.increments('vaccination_id').primary();

        // Foreign Key: Hangi kediye aşı yapıldı?
        table.integer('cat_id')
            .unsigned()
            .notNullable()
            .references('cat_id')
            .inTable('cats')
            .onDelete('CASCADE');

        // Aşı Bilgileri
        table.string('vaccine_name').notNullable(); // Örn: Karma, Kuduz
        table.date('vaccination_date').notNullable(); // Yapıldığı tarih
        table.date('next_due_date');                 // Bir sonraki aşı tarihi

        // Ekstra Notlar (Veteriner adı, aşı markası vb.)
        table.text('notes').nullable();

        // Zaman Damgaları (Diyagramdaki created_at ve updated_at)
        table.timestamps(true, true);
    });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function (knex) {
    return knex.schema.dropTableIfExists('vaccinations');
};