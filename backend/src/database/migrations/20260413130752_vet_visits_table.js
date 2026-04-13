/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function (knex) {
    return knex.schema.createTable('vet_visits', (table) => {
        // Primary Key
        table.increments('visit_id').primary();

        // Foreign Key: Hangi kedi ziyaret etti?
        table.integer('cat_id')
            .unsigned()
            .notNullable()
            .references('cat_id')
            .inTable('cats')
            .onDelete('CASCADE');

        // Tarih Alanları
        table.date('visit_date').notNullable(); // Ziyaret tarihi
        table.date('next_visit_date').nullable(); // Bir sonraki randevu tarihi

        // Metin Alanları (Detaylı bilgi için text tipi)
        table.text('reason').nullable();       // Ziyaret nedeni (Kontrol, hastalık vb.)
        table.text('doctor_notes').nullable(); // Veterinerin notları ve teşhisler

        // Zaman Damgaları
        table.timestamps(true, true);
    });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function (knex) {
    return knex.schema.dropTableIfExists('vet_visits');
};