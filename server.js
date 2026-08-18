const express = require('express');
const { Pool } = require('pg');
const path = require('path');
const app = express();

app.use(express.json());

// Servir ton site web d'origine à la racine
app.get('/', (req, res) => {
    res.sendFile('/home/williamdacoula/mon-site/index.html');
});

// Connexion à la base de données
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

// Démarrage du serveur
const PORT = process.env.PORT || 8000;
app.listen(PORT, () => {
    console.log(`Serveur démarré sur le port ${PORT}`);
});
