const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('./db');

const router = express.Router();

// Route d'inscription
router.post('/register', async (req, res) => {
    const { nom, email, telephone, password } = req.body;
    try {
        const userCheck = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
        if (userCheck.rows.length > 0) {
            return res.status(400).json({ error: 'Cet email est déjà utilisé' });
        }

        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        const newUser = await pool.query(
            'INSERT INTO users (nom, email, telephone, password_hash) VALUES ($1, $2, $3, $4) RETURNING id, nom, email',
            [nom, email, telephone, hashedPassword]
        );

        const userId = newUser.rows[0].id;
        await pool.query('INSERT INTO wallets (user_id, balance) VALUES ($1, $2)', [userId, 0.00]);

        res.status(201).json({ message: 'Compte créé avec succès', user: newUser.rows[0] });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Erreur serveur lors de la création du compte' });
    }
});

// Route de connexion
router.post('/login', async (req, res) => {
    const { email, password } = req.body;
    try {
        const userResult = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
        if (userResult.rows.length === 0) {
            return res.status(400).json({ error: 'Identifiants incorrects' });
        }

        const user = userResult.rows[0];
        const isMatch = await bcrypt.compare(password, user.password_hash);
        if (!isMatch) {
            return res.status(400).json({ error: 'Identifiants incorrects' });
        }

        const token = jwt.sign({ userId: user.id }, process.env.JWT_SECRET, { expiresIn: '24h' });

        res.json({ message: 'Connexion réussie', token, user: { id: user.id, nom: user.nom, email: user.email } });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Erreur serveur lors de la connexion' });
    }
});

module.exports = router;
