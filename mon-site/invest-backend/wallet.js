const express = require('express');
const pool = require('./db');
const { FedaPay, Transaction } = require('fedapay');

const router = express.Router();

// Configuration FedaPay Live
FedaPay.setApiKey('sk_live_mp7CCxmhorHDKS_2Y0rfB3-4');
FedaPay.setEnvironment('live');

// Récupérer le solde
router.get('/:userId', async (req, res) => {
  try {
    const result = await pool.query('SELECT balance, currency FROM wallets WHERE user_id = $1', [req.params.userId]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Portefeuille introuvable' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération du solde' });
  }
});

// Dépôt FedaPay
router.post('/deposit', async (req, res) => {
  const { userId, amount, email, name } = req.body;

  try {
    const numericAmount = parseInt(amount);

    if (isNaN(numericAmount) || numericAmount < 100) {
      return res.status(400).json({ error: 'Le montant minimum est de 100 FCFA' });
    }

    const transaction = await Transaction.create({
      description: `Rechargement InvestApp - Compte #${userId}`,
      amount: numericAmount,
      currency: { iso: 'XOF' },
      callback_url: 'http://localhost:8000',
      customer: {
        firstname: name || 'Utilisateur',
        lastname: 'InvestApp',
        email: email || 'client@example.com',
        phone_number: {
          number: '90000000',
          country: 'bj'
        }
      }
    });

    const token = await transaction.generateToken();

    res.json({ url: token.url });
  } catch (error) {
    console.error("Détails Erreur FedaPay :", error.response ? error.response.data : error);
    res.status(500).json({ error: "Impossible de générer le lien de paiement FedaPay." });
  }
});

module.exports = router;
