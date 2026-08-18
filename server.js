const express = require('express');
const cors = require('cors');
const path = require('path');
require('dotenv').config();
require('./cron');

const db = require('./db');
const authRoutes = require('./auth');
const walletRoutes = require('./wallet');
const investmentRoutes = require('./investment');

const app = express();

app.use(cors());
app.use(express.json());

app.use(express.static(path.join(__dirname, 'public')));

app.use('/api/auth', authRoutes);
app.use('/api/wallet', walletRoutes);
app.use('/api/investment', investmentRoutes);

// Page Admin HTML
app.get('/admin', (req, res) => {
  res.sendFile(path.join(__dirname, 'admin.html'));
});

// Récupérer tous les utilisateurs
app.get('/api/admin/users', async (req, res) => {
  try {
    const result = await db.query('SELECT id, name, email, created_at FROM users ORDER BY id DESC');
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération des utilisateurs' });
  }
});

// Récupérer l'historique des soldes / portefeuilles
app.get('/api/admin/wallets', async (req, res) => {
  try {
    const result = await db.query(`
      SELECT w.id, u.name, u.email, w.balance, w.currency 
      FROM wallets w 
      JOIN users u ON w.user_id = u.id 
      ORDER BY w.id DESC
    `);
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération des paiements' });
  }
});

const PORT = process.env.PORT || 8000;
app.listen(PORT, () => {
  console.log(`Serveur démarré sur http://localhost:${PORT}`);
});
