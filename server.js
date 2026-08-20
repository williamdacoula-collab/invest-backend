const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
require('dotenv').config();
const path = require('path');

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.static(__dirname));

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

// Création automatique de la table users au démarrage pour éviter les erreurs
pool.query(`
  CREATE TABLE IF NOT EXISTS users (
      id SERIAL PRIMARY KEY,
      name VARCHAR(255),
      email VARCHAR(255) UNIQUE NOT NULL,
      telephone VARCHAR(50),
      password VARCHAR(255) NOT NULL,
      solde NUMERIC DEFAULT 50000
  );
`).catch(err => console.error("Erreur création table :", err));

// Route d'inscription
app.post('/api/register', async (req, res) => {
  const { name, email, telephone, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ message: "Email et mot de passe obligatoires." });
  }
  try {
    const userCheck = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
    if (userCheck.rows.length > 0) {
      return res.status(400).json({ message: "Cet email est déjà utilisé." });
    }
    const newUser = await pool.query(
      'INSERT INTO users (name, email, telephone, password, solde) VALUES ($1, $2, $3, $4, 50000) RETURNING *',
      [name || "Utilisateur", email, telephone || "", password]
    );
    res.status(201).json({ message: "Inscription réussie", user: newUser.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur serveur lors de l'inscription." });
  }
});

// Route de connexion
app.post('/api/login', async (req, res) => {
  const { email, password } = req.body;
  try {
    const user = await pool.query('SELECT * FROM users WHERE email = $1 AND password = $2', [email, password]);
    if (user.rows.length === 0) {
      return res.status(400).json({ message: "Email ou mot de passe incorrect." });
    }
    res.json({ message: "Connexion réussie", user: user.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Erreur serveur." });
  }
});

// Route pour l'admin
app.get('/api/users', async (req, res) => {
  try {
    const result = await pool.query('SELECT id, name, email, solde FROM users');
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Erreur lors de la récupération des utilisateurs" });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Serveur démarré sur le port ${PORT}`));
