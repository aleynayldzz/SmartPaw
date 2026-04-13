/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function (knex) {
    return knex.schema.createTable('food_tracking', (table) => {
        // Primary Key: food_id
        table.increments('food_id').primary();

        // Foreign Key: cat_id (Kediler tablosuna bağlı)
        table.integer('cat_id')
            .unsigned()
            .notNullable()
            .references('cat_id')
            .inTable('cats')
            .onDelete('CASCADE');

        // Diyagramdaki Decimal Alanlar (Hassas ölçümler için)
        table.decimal('daily_food_grams', 8, 2);   // Günlük tüketim miktarı (gram)
        table.decimal('package_weight_kg', 8, 2); // Alınan paket ağırlığı (kg)
        table.decimal('remaining_weight_kg', 8, 2); // Kalan mama miktarı (kg)

        // Tarih Alanları
        table.date('last_updated');             // Son güncelleme tarihi
        table.date('estimated_finish_date');    // Tahmini bitiş tarihi (Algoritma için)

        // Standart zaman damgaları (Opsiyonel ama önerilir)
        table.timestamps(true, true);
    });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function (knex) {
    return knex.schema.dropTableIfExists('food_tracking');
};