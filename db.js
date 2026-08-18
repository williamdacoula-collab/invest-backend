const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.DATABASE_URL && process.env.DATABASE_URL.includes('localhost') 
    ? false 
    : { rejectUnauthorized: false }
});

pool.connect((err, client, release) => {
  if (err) {
    return console.error('Erreur de connexion à PostgreSQL :', err.stack);
  }
  console.log('Connecté avec succès à la base PostgreSQL !');
  release();
});

module.exports = pool;
