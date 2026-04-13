/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function (knex) {
    return knex.schema.createTable('weight_history', (table) => {
        // Primary Key: weight_id
        table.increments('weight_id').primary();

        // Foreign Key: Hangi kediye ait kilo kaydı?
        table.integer('cat_id')
            .unsigned()
            .notNullable()
            .references('cat_id')
            .inTable('cats')
            .onDelete('CASCADE');

        // Kilo Bilgisi (Hassas ölçüm için decimal)
        // 5 basamak toplam, 2 basamak virgülden sonra (Örn: 12.45 kg)
        table.decimal('weight', 5, 2).notNullable();

        // Kayıt Tarihi
        table.date('recorded_date').notNullable();

        // Zaman Damgaları (created_at ve updated_at)
        table.timestamps(true, true);
    });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function (knex) {
    return knex.schema.dropTableIfExists('weight_history');
};