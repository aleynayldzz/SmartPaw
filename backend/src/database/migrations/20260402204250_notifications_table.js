/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function (knex) {
    return knex.schema.createTable('notifications', (table) => {
        // Primary Key
        table.increments('notification_id').primary();

        // Foreign Key: Bildirimin kime gideceği
        table.integer('user_id')
            .unsigned()
            .notNullable()
            .references('user_id')
            .inTable('users')
            .onDelete('CASCADE');

        // Foreign Key: Bildirimin hangi kediyle ilgili olduğu
        table.integer('cat_id')
            .unsigned()
            .nullable() // Bazı bildirimler genel olabilir, kediyle ilgili olmayabilir
            .references('cat_id')
            .inTable('cats')
            .onDelete('CASCADE');

        // Bildirim Detayları
        table.enu('notification_type', ['health', 'care', 'feeding', 'task', 'system'])
            .defaultTo('system');
        table.string('title').notNullable();
        table.text('message').notNullable();

        // Planlama ve Durum Bilgileri
        table.date('scheduled_date').nullable(); // Gelecek bir tarih için planlanmışsa
        table.boolean('is_sent').defaultTo(false);
        table.timestamp('sent_at').nullable();
        table.boolean('is_read').defaultTo(false);

        // Zaman Damgaları
        table.timestamps(true, true);
    });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function (knex) {
    return knex.schema.dropTableIfExists('notifications');
};