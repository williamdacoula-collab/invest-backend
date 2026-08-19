const express = require('express');
const pool = require('./db');

const router = express.Router();

// Souscrire à un plan d'investissement
router.post('/subscribe', async (req, res) => {
    const { userId, planName, amount, dailyReturnRate, durationDays } = req.body;
    
    try {
        if (amount <= 0) {
            return res.status(400).json({ error: 'Le montant doit être supérieur à 0' });
        }

        // Vérifier le solde de l'utilisateur
        const walletResult = await pool.query('SELECT balance FROM wallets WHERE user_id = $1', [userId]);
        if (walletResult.rows.length === 0) {
            return res.status(404).json({ error: 'Portefeuille non trouvé' });
        }

        const balance = parseFloat(walletResult.rows[0].balance);
        if (balance < amount) {
            return res.status(400).json({ error: 'Solde insuffisant pour cet investissement' });
        }

        // Déduire le montant du portefeuille
        await pool.query('UPDATE wallets SET balance = balance - $1 WHERE user_id = $2', [amount, userId]);

        // Créer l'investissement
        const newInvestment = await pool.query(
            'INSERT INTO investments (user_id, plan_name, amount, daily_return_rate, duration_days) VALUES ($1, $2, $3, $4, $5) RETURNING *',
            [userId, planName, amount, dailyReturnRate, durationDays]
        );

        // Enregistrer la transaction
        const txRef = 'INV-' + Date.now() + '-' + Math.floor(Math.random() * 1000);
        await pool.query(
            'INSERT INTO transactions (user_id, transaction_ref, amount, type, status, payment_method) VALUES ($1, $2, $3, $4, $5, $6)',
            [userId, txRef, amount, 'INVESTMENT', 'SUCCESS', 'WALLET']
        );

        res.json({
            message: 'Investissement validé avec succès',
            investment: newInvestment.rows[0]
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Erreur lors de la souscription' });
    }
});

// Récupérer les investissements d'un utilisateur
router.get('/user/:userId', async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM investments WHERE user_id = $1 ORDER BY created_at DESC', [req.params.userId]);
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Erreur lors de la récupération des investissements' });
    }
});

module.exports = router;
