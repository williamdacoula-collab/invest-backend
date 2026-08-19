const express = require('express');
const { Pool } = require('pg');
const path = require('path');
const app = express();

app.use(express.json());

// Servir ton site web d'origine à la racine
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'index.html'));
});

// Route pour afficher ton panneau d'administration d'origine
app.get('/admin.html', (req, res) => {
    res.sendFile(path.join(__dirname, 'admin.html'));
});

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false }
});

// Route pour la connexion
app.post('/api/login', async (req, res) => {
    const { email, password } = req.body;
    try {
        const userCheck = await pool.query('SELECT * FROM users WHERE email = $1 AND password = $2', [email, password]);
        if (userCheck.rows.length === 0) {
            return res.status(401).json({ error: "Email ou mot de passe incorrect" });
        }
        res.json({ user: userCheck.rows[0] });
    } catch (err) {
        res.status(500).json({ error: "Erreur serveur lors de la connexion" });
    }
});

// Route pour les retraits
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

        const query = 'INSERT INTO transactions (user_id, type, amount, status) VALUES ($1, \'RETRAIT\', $2, \'EN_ATTENTE\') RETURNING *';
        const result = await pool.query(query, [user_id, amount]);

        res.json({ message: "Demande de retrait enregistrée", transaction: result.rows[0] });
    } catch (err) {
        res.status(500).json({ error: "Erreur serveur lors du retrait" });
    }
});

// Routes pour le panneau d'administration
app.get('/api/admin/users', async (req, res) => {
    try {
        const result = await pool.query('SELECT id, email, password FROM users');
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: "Erreur lors de la récupération des utilisateurs" });
    }
});

app.get('/api/admin/withdrawals', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT t.id, t.amount, t.status, u.email, u.numero 
            FROM transactions t 
            JOIN users u ON t.user_id = u.id 
            WHERE t.type = 'RETRAIT' AND t.status = 'EN_ATTENTE'
        `);
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: "Erreur lors de la récupération des retraits" });
    }
});

app.post('/api/admin/ban/:id', async (req, res) => {
    const userId = req.params.id;
    try {
        await pool.query('DELETE FROM users WHERE id = $1', [userId]);
        res.json({ message: "Utilisateur banni/supprimé avec succès" });
    } catch (err) {
        res.status(500).json({ error: "Erreur lors du bannissement" });
    }
});

app.post('/api/admin/validate-withdraw/:id', async (req, res) => {
    const txId = req.params.id;
    try {
        await pool.query("UPDATE transactions SET status = 'VALIDE' WHERE id = $1", [txId]);
        res.json({ message: "Retrait validé avec succès" });
    } catch (err) {
        res.status(500).json({ error: "Erreur lors de la validation" });
    }
});

// Démarrage du serveur (toujours à la toute fin)
const PORT = process.env.PORT || 8000;
app.listen(PORT, () => {
    console.log(`Serveur démarré sur le port ${PORT}`);
});
