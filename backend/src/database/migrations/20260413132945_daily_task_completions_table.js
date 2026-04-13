/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function (knex) {
    return knex.schema.createTable('daily_task_completions', (table) => {
        // Primary Key
        table.increments('completion_id').primary();

        // Foreign Key: Hangi kedi için?
        table.integer('cat_id')
            .unsigned()
            .notNullable()
            .references('cat_id')
            .inTable('cats')
            .onDelete('CASCADE');

        // Foreign Key: Hangi görev tamamlandı?
        table.integer('task_id')
            .unsigned()
            .notNullable()
            .references('task_id')
            .inTable('daily_tasks')
            .onDelete('CASCADE');

        // Durum ve Zaman Bilgileri
        table.date('completion_date').notNullable(); // Görevin planlandığı gün
        table.boolean('is_completed').defaultTo(false); // Tamamlandı mı?
        table.timestamp('completed_at').nullable();     // Tamamlandığı an (saat/dakika dahil)

        // Notlar (Örn: "Mamasını biraz geç yedi")
        table.text('notes').nullable();

        // Standart Zaman Damgaları (Opsiyonel ama takip için iyi pratiktir)
        table.timestamps(true, true);
    });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function (knex) {
    return knex.schema.dropTableIfExists('daily_task_completions');
};