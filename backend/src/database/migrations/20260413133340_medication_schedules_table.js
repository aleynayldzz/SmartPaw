/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function (knex) {
    return knex.schema.createTable('medication_schedules', (table) => {
        // Primary Key: schedule_id
        table.increments('schedule_id').primary();

        // Foreign Key: Hangi ilaca ait program?
        table.integer('medication_id')
            .unsigned()
            .notNullable()
            .references('medication_id')
            .inTable('medications')
            .onDelete('CASCADE');

        // Hatırlatıcı Saati (Diyagramdaki time tipi)
        table.time('reminder_time').notNullable();

        // Programın durumu (Aktif/Pasif)
        table.boolean('is_active').defaultTo(true);

        // Zaman Damgaları (İyi pratiktir, diyagramda olmasa da eklenebilir)
        table.timestamps(true, true);
    });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function (knex) {
    return knex.schema.dropTableIfExists('medication_schedules');
};