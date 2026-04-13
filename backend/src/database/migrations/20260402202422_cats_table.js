/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function (knex) {
    return knex.schema.createTable('cats', (table) => {
        // Primary Key
        table.increments('cat_id').primary();

        // Foreign Key: Bu kedinin sahibi olan kullanıcı
        table.integer('user_id')
            .unsigned()
            .notNullable()
            .references('user_id')
            .inTable('users')
            .onDelete('CASCADE');

        // Foreign Key: Kedinin ırkı (breeds tablosunu oluşturduğunu varsayıyoruz)
        table.integer('breed_id')
            .unsigned()
            .nullable()
            .references('breed_id')
            .inTable('cat_breeds')
            .onDelete('SET NULL');

        // Temel Bilgiler
        table.string('name').notNullable();
        table.date('birth_date');
        table.decimal('weight', 5, 2); // Örn: 12.45 kg (toplam 5 basamak, 2'si virgülden sonra)

        // Enum ve Boolean
        table.enu('gender', ['male', 'female', 'unknown']).defaultTo('unknown');
        table.boolean('is_neutered').defaultTo(false); // Kısırlaştırılmış mı?

        // Ekstra Bilgiler
        table.text('notes'); // Uzun notlar için text tipi daha uygundur

        // Zaman Damgaları (created_at ve updated_at)
        table.timestamps(true, true);
    });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function (knex) {
    return knex.schema.dropTableIfExists('cats');
};