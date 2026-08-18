const express = require('express');
const router = express.Router();
const db = require('./db');

// Inscription
router.post('/register', async (req, res) => {
  // Récupère le nom quelle que soit la clé envoyée par le frontend
  const name = req.body.name || req.body.fullName || req.body.fullname || req.body.nom;
  const { email, phone, password } = req.body;

  if (!name) {
    return res.status(400).json({ error: 'Le champ Nom complet est requis.' });
  }

  try {
    const result = await db.query(
      'INSERT INTO users (name, email, phone, password) VALUES ($1, $2, $3, $4) RETURNING id, name, email',
      [name, email, phone, password]
    );
    res.status(201).json({ message: 'Compte créé avec succès !', user: result.rows[0] });
  } catch (err) {
    console.error('Erreur inscription :', err);
    res.status(500).json({ error: 'Erreur SQL : ' + err.message });
  }
});

// Connexion
router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  try {
    const result = await db.query(
      'SELECT * FROM users WHERE email = $1 AND password = $2',
      [email, password]
    );
    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Email ou mot de passe incorrect' });
    }
    res.json({ message: 'Connexion réussie', user: result.rows[0] });
  } catch (err) {
    console.error('Erreur connexion :', err);
    res.status(500).json({ error: 'Erreur SQL : ' + err.message });
  }
});

module.exports = router;
