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
// Route pour effectuer un dépôt
app.post('/api/deposit', async (req, res) => {
    const { user_id, amount } = req.body;
    try {
        const query = `
            INSERT INTO transactions (user_id, type, amount, status) 
            VALUES ($1, 'DEPOT', $2, 'VALIDE') 
            RETURNING *;
        `;
        const values = [user_id, amount];
        const result = await pool.query(query, values);
        
        res.status(201).json({
            message: "Dépôt enregistré avec succès",
            transaction: result.rows[0]
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Erreur serveur lors du dépôt" });
    }
});

// Route pour demander un retrait
app.post('/api/withdraw', async (req, res) => {
    const { user_id, amount } = req.body;
    try {
        // Optionnel : vérifier si l'utilisateur a assez d'argent avant d'accepter la demande
        const query = `
            INSERT INTO transactions (user_id, type, amount, status) 
            VALUES ($1, 'RETRAIT', $2, 'EN_ATTENTE') 
            RETURNING *;
        `;
        const values = [user_id, amount];
        const result = await pool.query(query, values);

        res.status(201).json({
            message: "Demande de retrait enregistrée, en attente de validation",
            transaction: result.rows[0]
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Erreur serveur lors de la demande de retrait" });
    }
});
// Route pour valider un retrait
app.post('/api/admin/validate-withdraw', async (req, res) => {
    const { transaction_id } = req.body;
    try {
        const query = `UPDATE transactions SET status = 'VALIDE' WHERE id = $1 AND type = 'RETRAIT'`;
        await pool.query(query, [transaction_id]);
        res.json({ message: "Retrait validé avec succès" });
    } catch (err) {
        res.status(500).json({ error: "Erreur lors de la validation" });
    }
});
// Route d'inscription
app.post('/api/register', async (req, res) => {
    const { nom, email, password } = req.body;
    try {
        const query = `INSERT INTO users (nom, email, password) VALUES ($1, $2, $3) RETURNING id, nom, email`;
        const result = await pool.query(query, [nom, email, password]);
        res.json({ message: "Inscription réussie", user: result.rows[0] });
    } catch (err) {
        res.status(400).json({ error: "Cet email est déjà utilisé ou erreur de saisie" });
    }
});

// Route pour récupérer les transactions d'un utilisateur spécifique
app.get('/api/user-transactions/:user_id', async (req, res) => {
    const { user_id } = req.params;
    try {
        const query = `SELECT * FROM transactions WHERE user_id = $1 ORDER BY id DESC`;
        const result = await pool.query(query, [user_id]);
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: "Erreur lors de la récupération des transactions" });
    }
});

// Route admin pour lister tous les utilisateurs
app.get('/api/admin/users', async (req, res) => {
    try {
        const result = await pool.query(`SELECT id, nom, email, is_banned, created_at FROM users ORDER BY id DESC`);
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: "Erreur" });
    }
});

// Route admin pour bannir un utilisateur
app.post('/api/admin/ban-user', async (req, res) => {
    const { user_id } = req.body;
    try {
        await pool.query(`UPDATE users SET is_banned = TRUE WHERE id = $1`, [user_id]);
        res.json({ message: "Utilisateur banni avec succès" });
    } catch (err) {
        res.status(500).json({ error: "Erreur lors du bannissement" });
    }
});
app.post('/api/withdraw', async (req, res) => {
    const { user_id, amount } = req.body;
    try {
        const query = `INSERT INTO transactions (user_id, type, amount, status) VALUES ($1, 'RETRAIT', $2, 'EN_ATTENTE') RETURNING *`;
        const result = await pool.query(query, [user_id, amount]);
        res.json({ message: "Demande de retrait enregistrée", transaction: result.rows[0] });
    } catch (err) {
        res.status(500).json({ error: "Erreur serveur lors du retrait" });
    }
});
// Route Backend pour gérer les retraits de manière sécurisée
app.post('/api/withdraw', async (req, res) => {
    const { user_id, amount } = req.body;
    try {
        const userCheck = await pool.query('SELECT solde FROM users WHERE id = $1', [user_id]);
        if (userCheck.rows.length === 0) {
            return res.status(404).json({ error: "Utilisateur introuvable" });
        }

        const soldeActuel = parseFloat(userCheck.rows[0].solde || 0);

        if (parseFloat(amount) > soldeActuel) {
            return res.status(400).json({ error: "Solde insuffisant pour effectuer ce retrait." });
        }

        const query = `INSERT INTO transactions (user_id, type, amount, status) VALUES ($1, 'RETRAIT', $2, 'EN_ATTENTE') RETURNING *`;
        const result = await pool.query(query, [user_id, amount]);
        
        res.json({ message: "Demande de retrait enregistrée", transaction: result.rows[0] });
    } catch (err) {
        res.status(500).json({ error: "Erreur serveur lors du retrait" });
    }
});
