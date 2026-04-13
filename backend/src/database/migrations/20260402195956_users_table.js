/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function (knex) {
    return knex.schema.createTable('users', (table) => {
        // Primary Key: user_id (int)
        table.increments('user_id').primary();

        // Varchar alanlar
        table.string('name').notNullable();
        table.string('surname').notNullable();
        table.string('email').unique().notNullable(); // Email genellikle tekildir
        table.string('password_hash').notNullable();

        // Enum alanı (Diyagramdaki avatar_gender)
        table.enu('avatar_gender', ['male', 'female', 'unspecified']);

        // Boolean alanı
        table.boolean('is_verified').defaultTo(false);


        // created_at ve updated_at (Diyagramdaki timestamps)
        // true, true parametreleri hem created_at hem updated_at oluşturur ve otomatik yönetir
        table.timestamps(true, true);
    });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function (knex) {
    return knex.schema.dropTableIfExists('users');
};