/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function (knex) {
    return knex.schema.createTable('verification_codes', (table) => {
        // Primary Key
        table.increments('code_id').primary();

        // Foreign Key: users tablosundaki user_id'ye bağlanıyor
        table.integer('user_id')
            .unsigned()
            .notNullable()
            .references('user_id')
            .inTable('users')
            .onDelete('CASCADE'); // Kullanıcı silinirse kodları da silinir

        // Varchar ve Enum alanları
        table.string('code').notNullable();
        table.enu('purpose', ['email_verification', 'password_reset', 'login_2fa'])
            .defaultTo('email_verification');

        // Zaman damgaları
        table.timestamp('created_at').defaultTo(knex.fn.now());
        table.timestamp('expires_at').notNullable(); // Kodun son kullanma tarihi

        // Boolean durumu
        table.boolean('is_used').defaultTo(false);
    });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function (knex) {
    return knex.schema.dropTableIfExists('verification_codes');
};