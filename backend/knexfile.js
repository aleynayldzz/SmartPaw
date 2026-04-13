// Update with your config settings.

/**
 * @type { Object.<string, import("knex").Knex.Config> }
 */
module.exports = {
  development: {
    client: 'pg',
    connection: {
      host: '127.0.0.1',
      port: 5432,
      user: 'postgres',
      password: '310802', // pgAdmin'e girerken kullandığın şifre
      database: 'SmartPaw' // Ekran görüntüsündeki isimle birebir aynı olmalı
    },
    migrations: {
      directory: './src/database/migrations'
    }
  }
};