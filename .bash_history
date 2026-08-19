sudo apt update
sudo apt update -y curl git
sudo apt update
sudo apt install -y curl git
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
-v
node -v
npm -v
mkdir mon-site
cd mon-site
npm init -y
nano index.html
cd ~/mon-app
python3 -m http.server 8000
ls
cd ~/mon-site
[200~python3 -m http.server 8000~
python3 -m http.server 8000
nano indx.html
python3 -m http.server 8000
nano index.html
nano index html
nano index.html
python3 -m http.server 8000
mkdir invest-backend
cd invest-backend
npm init -y
npm install express pg dotenv bcryptjs jsonwebtoken cors axios
npm install --save-dev nodemon
"scripts": {
nano package.json
nano server.js
npm run dev
package.json
nano package.json
cat << 'EOF' > package.json
{
  "name": "invest-backend",
  "version": "1.0.0",
  "description": "",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "dependencies": {
    "axios": "^1.19.0",
    "bcryptjs": "^3.0.3",
    "cors": "^2.8.6",
    "dotenv": "^17.4.2",
    "express": "^5.2.1",
    "jsonwebtoken": "^9.0.3",
    "pg": "^8.23.0"
  },
  "devDependencies": {
    "nodemon": "^3.1.14"
  }
}
EOF

npm run dev
sudo apt update && sudo apt install postgresql postgresql-contrib -y
sudo service postgresql start
sudo -u postgres psql
cat << 'EOF' > .env
PORT=8000
DB_USER=invest_user
DB_PASSWORD=MonMotDePasseSecurise123
DB_HOST=localhost
DB_PORT=5432
DB_NAME=invest_db
JWT_SECRET=super_cle_secrete_invest_2026
EOF

cat << 'EOF' > db.js
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
});

pool.connect((err, client, release) => {
  if (err) {
    return console.error('Erreur de connexion à PostgreSQL :', err.stack);
  }
  console.log('Connecté avec succès à la base PostgreSQL !');
  release();
});

module.exports = pool;
EOF

cat << 'EOF' > server.js
const express = require('express');
const cors = require('cors');
require('dotenv').config();
const db = require('./db');

const app = express();

app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
    res.send('API Investissement active !');
});

const PORT = process.env.PORT || 8000;
app.listen(PORT, () => {
    console.log(`Serveur démarré sur http://localhost:${PORT}`);
});
EOF

cat << 'EOF' > auth.js
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
EOF

cat << 'EOF' > server.js
const express = require('express');
const cors = require('cors');
require('dotenv').config();
const db = require('./db');
const authRoutes = require('./auth');

const app = express();

app.use(cors());
app.use(express.json());

app.use('/api/auth', authRoutes);

app.get('/', (req, res) => {
    res.send('API Investissement active !');
});

const PORT = process.env.PORT || 8000;
app.listen(PORT, () => {
    console.log(`Serveur démarré sur http://localhost:${PORT}`);
});
EOF

cat << 'EOF' > wallet.js
const express = require('express');
const pool = require('./db');

const router = express.Router();

// Récupérer le solde de l'utilisateur
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

// Simuler un dépôt (Wave, Orange, MTN, Moov)
router.post('/deposit', async (req, res) => {
    const { userId, amount, paymentMethod } = req.body;
    try {
        if (amount <= 0) {
            return res.status(400).json({ error: 'Le montant doit être supérieur à 0' });
        }

        const txRef = 'DEP-' + Date.now() + '-' + Math.floor(Math.random() * 1000);

        // Enregistrer la transaction
        await pool.query(
            'INSERT INTO transactions (user_id, transaction_ref, amount, type, status, payment_method) VALUES ($1, $2, $3, $4, $5, $6)',
            [userId, txRef, amount, 'DEPOSIT', 'SUCCESS', paymentMethod]
        );

        // Mettre à jour le solde
        const updatedWallet = await pool.query(
            'UPDATE wallets SET balance = balance + $1, updated_at = CURRENT_TIMESTAMP WHERE user_id = $2 RETURNING balance',
            [amount, userId]
        );

        res.json({
            message: 'Dépôt effectué avec succès',
            newBalance: updatedWallet.rows[0].balance,
            transactionRef: txRef
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Erreur lors du traitement du dépôt' });
    }
});

module.exports = router;
EOF

cat << 'EOF' > server.js
const express = require('express');
const cors = require('cors');
require('dotenv').config();
const db = require('./db');
const authRoutes = require('./auth');
const walletRoutes = require('./wallet');

const app = express();

app.use(cors());
app.use(express.json());

app.use('/api/auth', authRoutes);
app.use('/api/wallet', walletRoutes);

app.get('/', (req, res) => {
    res.send('API Investissement active !');
});

const PORT = process.env.PORT || 8000;
app.listen(PORT, () => {
    console.log(`Serveur démarré sur http://localhost:${PORT}`);
});
EOF

sudo -u postgres psql -d invest_db -c "
CREATE TABLE IF NOT EXISTS investments (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id) ON DELETE CASCADE,
    plan_name VARCHAR(100) NOT NULL,
    amount NUMERIC(15, 2) NOT NULL,
    daily_return_rate NUMERIC(5, 2) NOT NULL,
    duration_days INT NOT NULL,
    status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'COMPLETED', 'CANCELLED')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
GRANT ALL ON TABLE investments TO invest_user;
GRANT ALL ON SEQUENCE investments_id_seq TO invest_user;
"
cat << 'EOF' > investment.js
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
EOF

cat << 'EOF' > server.js
const express = require('express');
const cors = require('cors');
require('dotenv').config();
const db = require('./db');
const authRoutes = require('./auth');
const walletRoutes = require('./wallet');
const investmentRoutes = require('./investment');

const app = express();

app.use(cors());
app.use(express.json());

app.use('/api/auth', authRoutes);
app.use('/api/wallet', walletRoutes);
app.use('/api/investment', investmentRoutes);

app.get('/', (req, res) => {
    res.send('API Investissement active !');
});

const PORT = process.env.PORT || 8000;
app.listen(PORT, () => {
    console.log(`Serveur démarré sur http://localhost:${PORT}`);
});
EOF

mkdir -p public 
cat << 'EOF' > public/index.html
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>InvestApp - Plateforme d'Investissement</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { background-color: #f8f9fa; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; }
        .hero { background: linear-gradient(135deg, #0d6efd, #0a58ca); color: white; padding: 40px 0; border-radius: 0 0 20px 20px; }
        .card-custom { border: none; border-radius: 15px; box-shadow: 0 4px 15px rgba(0,0,0,0.05); }
        .btn-custom { border-radius: 10px; font-weight: 600; padding: 10px 20px; }
    </style>
</head>
<body>

    <div class="hero text-center mb-4">
        <h1 class="fw-bold">InvestApp</h1>
        <p class="lead">Faites fructifier vos économies simplement</p>
    </div>

    <div class="container" id="app">
        <!-- Zone Connexion / Inscription -->
        <div id="auth-section" class="row justify-content-center">
            <div class="col-md-5 mb-4">
                <div class="card card-custom p-4">
                    <h3 class="text-center mb-3">Connexion</h3>
                    <form id="login-form">
                        <div class="mb-3">
                            <label class="form-label">Email</label>
                            <input type="email" id="login-email" class="form-control" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Mot de passe</label>
                            <input type="password" id="login-password" class="form-control" required>
                        </div>
                        <button type="submit" class="btn btn-primary w-100 btn-custom">Se connecter</button>
                    </form>
                </div>
            </div>

            <div class="col-md-5">
                <div class="card card-custom p-4">
                    <h3 class="text-center mb-3">Créer un compte</h3>
                    <form id="register-form">
                        <div class="mb-3">
                            <label class="form-label">Nom complet</label>
                            <input type="text" id="reg-nom" class="form-control" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Email</label>
                            <input type="email" id="reg-email" class="form-control" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Téléphone (Wave / Orange Money)</label>
                            <input type="text" id="reg-phone" class="form-control" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Mot de passe</label>
                            <input type="password" id="reg-password" class="form-control" required>
                        </div>
                        <button type="submit" class="btn btn-success w-100 btn-custom">S'inscrire</button>
                    </form>
                </div>
            </div>
        </div>

        <!-- Tableau de Bord Utilisateur (Masqué par défaut) -->
        <div id="dashboard-section" class="style-display: none;" style="display: none;">
            <div class="row mb-4">
                <div class="col-md-12 text-end mb-2">
                    <button class="btn btn-outline-danger btn-sm" onclick="logout()">Déconnexion</button>
                </div>
                <div class="col-md-6 mb-3">
                    <div class="card card-custom p-4 text-center bg-white">
                        <h5 class="text-muted">Solde Actuel</h5>
                        <h2 class="text-primary fw-bold" id="user-balance">0 FCFA</h2>
                    </div>
                </div>
                <div class="col-md-6 mb-3">
                    <div class="card card-custom p-4 bg-white">
                        <h5>Recharger le solde (Dépôt)</h5>
                        <div class="input-group mb-2">
                            <input type="number" id="deposit-amount" class="form-control" placeholder="Montant en FCFA">
                            <button class="btn btn-success" onclick="depositMoney()">Déposer</button>
                        </div>
                    </div>
                </div>
            </div>

            <h4 class="mb-3">Plans d'Investissement Disponibles</h4>
            <div class="row">
                <div class="col-md-4 mb-3">
                    <div class="card card-custom p-3 text-center">
                        <h5 class="fw-bold text-primary">Plan Bronze</h5>
                        <p class="h4">5 000 FCFA</p>
                        <p class="text-success fw-bold">+2.5% / jour (30 jours)</p>
                        <button class="btn btn-primary btn-custom" onclick="invest('Plan Bronze', 5000, 2.5, 30)">Investir</button>
                    </div>
                </div>
                <div class="col-md-4 mb-3">
                    <div class="card card-custom p-3 text-center">
                        <h5 class="fw-bold text-warning">Plan Argent</h5>
                        <p class="h4">20 000 FCFA</p>
                        <p class="text-success fw-bold">+3.5% / jour (30 jours)</p>
                        <button class="btn btn-warning text-white btn-custom" onclick="invest('Plan Argent', 20000, 3.5, 30)">Investir</button>
                    </div>
                </div>
                <div class="col-md-4 mb-3">
                    <div class="card card-custom p-3 text-center">
                        <h5 class="fw-bold text-danger">Plan Or</h5>
                        <p class="h4">50 000 FCFA</p>
                        <p class="text-success fw-bold">+5.0% / jour (30 jours)</p>
                        <button class="btn btn-danger btn-custom" onclick="invest('Plan Or', 50000, 5.0, 30)">Investir</button>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script>
        let currentUser = null;

        document.getElementById('register-form').addEventListener('submit', async (e) => {
            e.preventDefault();
            const nom = document.getElementById('reg-nom').value;
            const email = document.getElementById('reg-email').value;
            const telephone = document.getElementById('reg-phone').value;
            const password = document.getElementById('reg-password').value;

            const res = await fetch('/api/auth/register', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ nom, email, telephone, password })
            });
            const data = await res.json();
            if (res.ok) {
                alert('Compte créé avec succès ! Connectez-vous.');
            } else {
                alert(data.error);
            }
        });

        document.getElementById('login-form').addEventListener('submit', async (e) => {
            e.preventDefault();
            const email = document.getElementById('login-email').value;
            const password = document.getElementById('login-password').value;

            const res = await fetch('/api/auth/login', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ email, password })
            });
            const data = await res.json();
            if (res.ok) {
                currentUser = data.user;
                document.getElementById('auth-section').style.display = 'none';
                document.getElementById('dashboard-section').style.display = 'block';
                loadBalance();
            } else {
                alert(data.error);
            }
        });

        async function loadBalance() {
            if (!currentUser) return;
            const res = await fetch(`/api/wallet/${currentUser.id}`);
            const data = await res.json();
            if (res.ok) {
                document.getElementById('user-balance').innerText = `${parseFloat(data.balance).toLocaleString()} FCFA`;
            }
        }

        async function depositMoney() {
            const amount = parseFloat(document.getElementById('deposit-amount').value);
            if (!amount || amount <= 0) return alert('Saisissez un montant valide');

            const res = await fetch('/api/wallet/deposit', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ userId: currentUser.id, amount, paymentMethod: 'MOBILE_MONEY' })
            });
            const data = await res.json();
            if (res.ok) {
                alert('Dépôt réussi !');
                document.getElementById('deposit-amount').value = '';
                loadBalance();
            } else {
                alert(data.error);
            }
        }

        async function invest(planName, amount, dailyReturnRate, durationDays) {
            if (!currentUser) return;
            const res = await fetch('/api/investment/subscribe', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ userId: currentUser.id, planName, amount, dailyReturnRate, durationDays })
            });
            const data = await res.json();
            if (res.ok) {
                alert(`Souscription au ${planName} validée !`);
                loadBalance();
            } else {
                alert(data.error);
            }
        }

        function logout() {
            currentUser = null;
            document.getElementById('auth-section').style.display = 'flex';
            document.getElementById('dashboard-section').style.display = 'none';
        }
    </script>
</body>
</html>
EOF

cat << 'EOF' > server.js
const express = require('express');
const cors = require('cors');
const path = require('path');
require('dotenv').config();
const db = require('./db');
const authRoutes = require('./auth');
const walletRoutes = require('./wallet');
const investmentRoutes = require('./investment');

const app = express();

app.use(cors());
app.use(express.json());

// Servir les fichiers statiques de l'interface
app.use(express.static(path.join(__dirname, 'public')));

app.use('/api/auth', authRoutes);
app.use('/api/wallet', walletRoutes);
app.use('/api/investment', investmentRoutes);

const PORT = process.env.PORT || 8000;
app.listen(PORT, () => {
    console.log(`Serveur démarré sur http://localhost:${PORT}`);
});
EOF

cat << 'EOF' > .env
PORT=8000
DB_USER=invest_user
DB_PASSWORD=MonMotDePasseSecurise123
DB_HOST=localhost
DB_PORT=5432
DB_NAME=invest_db
JWT_SECRET=super_cle_secrete_invest_2026

# Identifiants CinetPay
CINETPAY_API_KEY=1234567890abcdef1234567890
CINETPAY_SITE_ID=123456
BASE_URL=http://localhost:8000
EOF

cat << 'EOF' > wallet.js
const express = require('express');
const axios = require('axios');
const pool = require('./db');

const router = express.Router();

// Récupérer le solde de l'utilisateur
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

// Initialiser une demande de paiement Mobile Money via CinetPay
router.post('/deposit', async (req, res) => {
    const { userId, amount } = req.body;
    try {
        if (amount < 100) {
            return res.status(400).json({ error: 'Le montant minimum est de 100 FCFA' });
        }

        const transactionRef = 'DEP-' + Date.now() + '-' + Math.floor(Math.random() * 1000);

        // Récupérer les infos utilisateur
        const userRes = await pool.query('SELECT nom, email, telephone FROM users WHERE id = $1', [userId]);
        if (userRes.rows.length === 0) {
            return res.status(404).json({ error: 'Utilisateur introuvable' });
        }
        const user = userRes.rows[0];

        // Enregistrer la transaction en PENDING
        await pool.query(
            'INSERT INTO transactions (user_id, transaction_ref, amount, type, status, payment_method) VALUES ($1, $2, $3, $4, $5, $6)',
            [userId, transactionRef, amount, 'DEPOSIT', 'PENDING', 'MOBILE_MONEY']
        );

        // Appel API CinetPay pour obtenir le lien de paiement
        const cinetPayPayload = {
            apikey: process.env.CINETPAY_API_KEY,
            site_id: process.env.CINETPAY_SITE_ID,
            transaction_id: transactionRef,
            amount: amount,
            currency: 'XOF',
            description: 'Dépôt sur le compte InvestApp',
            return_url: `${process.env.BASE_URL}/`,
            notify_url: `${process.env.BASE_URL}/api/wallet/notify`,
            customer_name: user.nom,
            customer_surname: user.nom,
            customer_email: user.email,
            customer_phone_number: user.telephone
        };

        const response = await axios.post('https://api-checkout.cinetpay.com/v2/payment', cinetPayPayload);

        if (response.data.code === '201') {
            // Renvoie le lien de paiement vers la passerelle Mobile Money
            res.json({ paymentUrl: response.data.data.payment_url });
        } else {
            res.status(400).json({ error: response.data.message || 'Erreur d’initialisation du paiement' });
        }
    } catch (err) {
        console.error('Erreur CinetPay:', err.response ? err.response.data : err.message);
        res.status(500).json({ error: 'Impossible de contacter le service de paiement' });
    }
});

// Notification CinetPay (Webhook de confirmation de paiement)
router.post('/notify', async (req, res) => {
    const { cpm_trans_id, cpm_site_id } = req.body;
    try {
        // Vérification du statut de la transaction auprès de CinetPay
        const checkPayload = {
            apikey: process.env.CINETPAY_API_KEY,
            site_id: cpm_site_id || process.env.CINETPAY_SITE_ID,
            transaction_id: cpm_trans_id
        };

        const checkRes = await axios.post('https://api-checkout.cinetpay.com/v2/payment/check', checkPayload);
        const data = checkRes.data;

        if (data.code === '00') {
            // Paiement validé avec succès
            const txRes = await pool.query(
                "SELECT user_id, amount, status FROM transactions WHERE transaction_ref = $1",
                [cpm_trans_id]
            );

            if (txRes.rows.length > 0 && txRes.rows[0].status === 'PENDING') {
                const { user_id, amount } = txRes.rows[0];

                // Mettre à jour le statut de la transaction
                await pool.query(
                    "UPDATE transactions SET status = 'SUCCESS' WHERE transaction_ref = $1",
                    [cpm_trans_id]
                );

                // Créditer le solde de l'utilisateur
                await pool.query(
                    "UPDATE wallets SET balance = balance + $1, updated_at = CURRENT_TIMESTAMP WHERE user_id = $2",
                    [amount, user_id]
                );
            }
        }
        res.status(200).send('OK');
    } catch (err) {
        console.error('Erreur webhook CinetPay:', err.message);
        res.status(500).send('Erreur');
    }
});

module.exports = router;
EOF

cat << 'EOF' > public/index.html
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>InvestApp - Plateforme d'Investissement</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { background-color: #f8f9fa; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; }
        .hero { background: linear-gradient(135deg, #0d6efd, #0a58ca); color: white; padding: 40px 0; border-radius: 0 0 20px 20px; }
        .card-custom { border: none; border-radius: 15px; box-shadow: 0 4px 15px rgba(0,0,0,0.05); }
        .btn-custom { border-radius: 10px; font-weight: 600; padding: 10px 20px; }
    </style>
</head>
<body>

    <div class="hero text-center mb-4">
        <h1 class="fw-bold">InvestApp</h1>
        <p class="lead">Faites fructifier vos économies simplement</p>
    </div>

    <div class="container" id="app">
        <!-- Zone Connexion / Inscription -->
        <div id="auth-section" class="row justify-content-center">
            <div class="col-md-5 mb-4">
                <div class="card card-custom p-4">
                    <h3 class="text-center mb-3">Connexion</h3>
                    <form id="login-form">
                        <div class="mb-3">
                            <label class="form-label">Email</label>
                            <input type="email" id="login-email" class="form-control" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Mot de passe</label>
                            <input type="password" id="login-password" class="form-control" required>
                        </div>
                        <button type="submit" class="btn btn-primary w-100 btn-custom">Se connecter</button>
                    </form>
                </div>
            </div>

            <div class="col-md-5">
                <div class="card card-custom p-4">
                    <h3 class="text-center mb-3">Créer un compte</h3>
                    <form id="register-form">
                        <div class="mb-3">
                            <label class="form-label">Nom complet</label>
                            <input type="text" id="reg-nom" class="form-control" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Email</label>
                            <input type="email" id="reg-email" class="form-control" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Téléphone (Ex: 0700000000)</label>
                            <input type="text" id="reg-phone" class="form-control" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Mot de passe</label>
                            <input type="password" id="reg-password" class="form-control" required>
                        </div>
                        <button type="submit" class="btn btn-success w-100 btn-custom">S'inscrire</button>
                    </form>
                </div>
            </div>
        </div>

        <!-- Tableau de Bord Utilisateur (Masqué par défaut) -->
        <div id="dashboard-section" style="display: none;">
            <div class="row mb-4">
                <div class="col-md-12 text-end mb-2">
                    <button class="btn btn-outline-danger btn-sm" onclick="logout()">Déconnexion</button>
                </div>
                <div class="col-md-6 mb-3">
                    <div class="card card-custom p-4 text-center bg-white">
                        <h5 class="text-muted">Solde Actuel</h5>
                        <h2 class="text-primary fw-bold" id="user-balance">0 FCFA</h2>
                    </div>
                </div>
                <div class="col-md-6 mb-3">
                    <div class="card card-custom p-4 bg-white">
                        <h5>Recharger le solde (Mobile Money / Wave)</h5>
                        <div class="input-group mb-2">
                            <input type="number" id="deposit-amount" class="form-control" placeholder="Montant en FCFA">
                            <button class="btn btn-success" onclick="depositMoney()">Payer par Mobile Money</button>
                        </div>
                    </div>
                </div>
            </div>

            <h4 class="mb-3">Plans d'Investissement Disponibles</h4>
            <div class="row">
                <div class="col-md-4 mb-3">
                    <div class="card card-custom p-3 text-center">
                        <h5 class="fw-bold text-primary">Plan Bronze</h5>
                        <p class="h4">5 000 FCFA</p>
                        <p class="text-success fw-bold">+2.5% / jour (30 jours)</p>
                        <button class="btn btn-primary btn-custom" onclick="invest('Plan Bronze', 5000, 2.5, 30)">Investir</button>
                    </div>
                </div>
                <div class="col-md-4 mb-3">
                    <div class="card card-custom p-3 text-center">
                        <h5 class="fw-bold text-warning">Plan Argent</h5>
                        <p class="h4">20 000 FCFA</p>
                        <p class="text-success fw-bold">+3.5% / jour (30 jours)</p>
                        <button class="btn btn-warning text-white btn-custom" onclick="invest('Plan Argent', 20000, 3.5, 30)">Investir</button>
                    </div>
                </div>
                <div class="col-md-4 mb-3">
                    <div class="card card-custom p-3 text-center">
                        <h5 class="fw-bold text-danger">Plan Or</h5>
                        <p class="h4">50 000 FCFA</p>
                        <p class="text-success fw-bold">+5.0% / jour (30 jours)</p>
                        <button class="btn btn-danger btn-custom" onclick="invest('Plan Or', 50000, 5.0, 30)">Investir</button>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script>
        let currentUser = null;

        document.getElementById('register-form').addEventListener('submit', async (e) => {
            e.preventDefault();
            const nom = document.getElementById('reg-nom').value;
            const email = document.getElementById('reg-email').value;
            const telephone = document.getElementById('reg-phone').value;
            const password = document.getElementById('reg-password').value;

            const res = await fetch('/api/auth/register', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ nom, email, telephone, password })
            });
            const data = await res.json();
            if (res.ok) {
                alert('Compte créé avec succès ! Connectez-vous.');
            } else {
                alert(data.error);
            }
        });

        document.getElementById('login-form').addEventListener('submit', async (e) => {
            e.preventDefault();
            const email = document.getElementById('login-email').value;
            const password = document.getElementById('login-password').value;

            const res = await fetch('/api/auth/login', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ email, password })
            });
            const data = await res.json();
            if (res.ok) {
                currentUser = data.user;
                document.getElementById('auth-section').style.display = 'none';
                document.getElementById('dashboard-section').style.display = 'block';
                loadBalance();
            } else {
                alert(data.error);
            }
        });

        async function loadBalance() {
            if (!currentUser) return;
            const res = await fetch(`/api/wallet/${currentUser.id}`);
            const data = await res.json();
            if (res.ok) {
                document.getElementById('user-balance').innerText = `${parseFloat(data.balance).toLocaleString()} FCFA`;
            }
        }

        async function depositMoney() {
            const amount = parseFloat(document.getElementById('deposit-amount').value);
            if (!amount || amount < 100) return alert('Saisissez un montant valide (minimum 100 FCFA)');

            const res = await fetch('/api/wallet/deposit', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ userId: currentUser.id, amount })
            });
            const data = await res.json();
            if (res.ok && data.paymentUrl) {
                // Redirection vers la passerelle de paiement
                window.location.href = data.paymentUrl;
            } else {
                alert(data.error || 'Erreur lors de la redirection vers le paiement');
            }
        }

        async function invest(planName, amount, dailyReturnRate, durationDays) {
            if (!currentUser) return;
            const res = await fetch('/api/investment/subscribe', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ userId: currentUser.id, planName, amount, dailyReturnRate, durationDays })
            });
            const data = await res.json();
            if (res.ok) {
                alert(`Souscription au ${planName} validée !`);
                loadBalance();
            } else {
                alert(data.error);
            }
        }

        function logout() {
            currentUser = null;
            document.getElementById('auth-section').style.display = 'flex';
            document.getElementById('dashboard-section').style.display = 'none';
        }
    </script>
</body>
</html>
EOF

cat << 'EOF' > wallet.js
const express = require('express');
const pool = require('./db');

const router = express.Router();

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

// Dépôt (Mode simulation)
router.post('/deposit', async (req, res) => {
    const { userId, amount } = req.body;
    try {
        if (amount < 100) {
            return res.status(400).json({ error: 'Le montant minimum est de 100 FCFA' });
        }

        const transactionRef = 'DEP-' + Date.now();

        // Enregistrer la transaction
        await pool.query(
            'INSERT INTO transactions (user_id, transaction_ref, amount, type, status, payment_method) VALUES ($1, $2, $3, $4, $5, $6)',
            [userId, transactionRef, amount, 'DEPOSIT', 'SUCCESS', 'MOBILE_MONEY']
        );

        // Créditer le solde
        await pool.query(
            'UPDATE wallets SET balance = balance + $1, updated_at = CURRENT_TIMESTAMP WHERE user_id = $2',
            [amount, userId]
        );

        res.json({ message: 'Dépôt effectué avec succès' });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Erreur lors du dépôt' });
    }
});

module.exports = router;
EOF

npm install node-cron
cat << 'EOF' > cron.js
const cron = require('node-cron');
const pool = require('./db');

async function processDailyReturns() {
    console.log('[CRON] Calcul des rendements journaliers en cours...');
    try {
        const investments = await pool.query("SELECT * FROM investments WHERE status = 'ACTIVE'");

        for (const inv of investments.rows) {
            const dailyGain = (parseFloat(inv.amount) * parseFloat(inv.daily_return_rate)) / 100;
            
            await pool.query(
                'UPDATE wallets SET balance = balance + $1, updated_at = CURRENT_TIMESTAMP WHERE user_id = $2',
                [dailyGain, inv.user_id]
            );

            const txRef = 'GAIN-' + Date.now() + '-' + Math.floor(Math.random() * 1000);
            await pool.query(
                'INSERT INTO transactions (user_id, transaction_ref, amount, type, status, payment_method) VALUES ($1, $2, $3, $4, $5, $6)',
                [inv.user_id, txRef, dailyGain, 'INVESTMENT_RETURN', 'SUCCESS', 'SYSTEM']
            );

            console.log(`[CRON] +${dailyGain} FCFA versés à l'utilisateur ID: ${inv.user_id} (${inv.plan_name})`);
        }
    } catch (err) {
        console.error('[CRON] Erreur lors du calcul des gains :', err);
    }
}

cron.schedule('0 0 * * *', () => {
    processDailyReturns();
});

module.exports = { processDailyReturns };
EOF

cat << 'EOF' > server.js
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

const PORT = process.env.PORT || 8000;
app.listen(PORT, () => {
    console.log(`Serveur démarré sur http://localhost:${PORT}`);
});
EOF

cat << 'EOF' > server.js
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

const PORT = process.env.PORT || 8000;
app.listen(PORT, () => {
    console.log(`Serveur démarré sur http://localhost:${PORT}`);
});
EO

[200~cat << 'EOF' > server.js
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

const PORT = process.env.PORT || 8000;
app.listen(PORT, () => {
    console.log(`Serveur démarré sur http://localhost:${PORT}`);
});
EOF~

cat << 'EOF' > server.js
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

const PORT = process.env.PORT || 8000;
app.listen(PORT, () => {
    console.log(`Serveur démarré sur http://localhost:${PORT}`);
});
EOF

node server.js
cd ~/mon-site/invest-backend
node -e '
const fs = require("fs");
const code = `<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>InvestApp - Plateforme d"Investissement</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { background-color: #f8f9fa; font-family: "Segoe UI", Tahoma, Geneva, Verdana, sans-serif; }
        .hero { background: linear-gradient(135deg, #0d6efd, #0a58ca); color: white; padding: 40px 0; border-radius: 0 0 20px 20px; }
        .card-custom { border: none; border-radius: 15px; box-shadow: 0 4px 15px rgba(0,0,0,0.05); }
        .btn-custom { border-radius: 10px; font-weight: 600; padding: 10px 20px; }
    </style>
</head>
<body>

    <div class="hero text-center mb-4">
        <h1 class="fw-bold">InvestApp</h1>
        <p class="lead">Faites fructifier vos économies simplement</p>
    </div>

    <div class="container" id="app">
        <div id="auth-section" class="row justify-content-center">
            <div class="col-md-5 mb-4">
                <div class="card card-custom p-4">
                    <h3 class="text-center mb-3">Connexion</h3>
                    <form id="login-form">
                        <div class="mb-3">
                            <label class="form-label">Email</label>
                            <input type="email" id="login-email" class="form-control" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Mot de passe</label>
                            <input type="password" id="login-password" class="form-control" required>
                        </div>
                        <button type="submit" class="btn btn-primary w-100 btn-custom">Se connecter</button>
                    </form>
                </div>
            </div>

            <div class="col-md-5">
                <div class="card card-custom p-4">
                    <h3 class="text-center mb-3">Créer un compte</h3>
                    <form id="register-form">
                        <div class="mb-3">
                            <label class="form-label">Nom complet</label>
                            <input type="text" id="reg-nom" class="form-control" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Email</label>
                            <input type="email" id="reg-email" class="form-control" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Téléphone</label>
                            <input type="text" id="reg-phone" class="form-control" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Mot de passe</label>
                            <input type="password" id="reg-password" class="form-control" required>
                        </div>
                        <button type="submit" class="btn btn-success w-100 btn-custom">S"inscrire</button>
                    </form>
                </div>
            </div>
        </div>

        <div id="dashboard-section" style="display: none;">
            <div class="row mb-4">
                <div class="col-md-12 text-end mb-2">
                    <button class="btn btn-outline-danger btn-sm" onclick="logout()">Déconnexion</button>
                </div>
                <div class="col-md-6 mb-3">
                    <div class="card card-custom p-4 text-center bg-white">
                        <h5 class="text-muted">Solde Actuel</h5>
                        <h2 class="text-primary fw-bold" id="user-balance">0 FCFA</h2>
                    </div>
                </div>
                <div class="col-md-6 mb-3">
                    <div class="card card-custom p-4 bg-white">
                        <h5>Recharger le solde (Dépôt)</h5>
                        <div class="input-group mb-2">
                            <input type="number" id="deposit-amount" class="form-control" placeholder="Montant en FCFA">
                            <button class="btn btn-success" onclick="depositMoney()">Déposer</button>
                        </div>
                    </div>
                </div>
            </div>

            <h4 class="mb-3">Plans d"Investissement Disponibles</h4>
            <div class="row mb-4">
                <div class="col-md-4 mb-3">
                    <div class="card card-custom p-3 text-center">
                        <h5 class="fw-bold text-primary">Plan Bronze</h5>
                        <p class="h4">5 000 FCFA</p>
                        <p class="text-success fw-bold">+2.5% / jour (30 jours)</p>
                        <button class="btn btn-primary btn-custom" onclick="invest(\x27Plan Bronze\x27, 5000, 2.5, 30)">Investir</button>
                    </div>
                </div>
                <div class="col-md-4 mb-3">
                    <div class="card card-custom p-3 text-center">
                        <h5 class="fw-bold text-warning">Plan Argent</h5>
                        <p class="h4">20 000 FCFA</p>
                        <p class="text-success fw-bold">+3.5% / jour (30 jours)</p>
                        <button class="btn btn-warning text-white btn-custom" onclick="invest(\x27Plan Argent\x27, 20000, 3.5, 30)">Investir</button>
                    </div>
                </div>
                <div class="col-md-4 mb-3">
                    <div class="card card-custom p-3 text-center">
                        <h5 class="fw-bold text-danger">Plan Or</h5>
                        <p class="h4">50 000 FCFA</p>
                        <p class="text-success fw-bold">+5.0% / jour (30 jours)</p>
                        <button class="btn btn-danger btn-custom" onclick="invest(\x27Plan Or\x27, 50000, 5.0, 30)">Investir</button>
                    </div>
                </div>
            </div>

            <h4 class="mb-3">Mes Investissements en cours</h4>
            <div class="card card-custom p-3 bg-white mb-4">
                <div class="table-responsive">
                    <table class="table align-middle">
                        <thead>
                            <tr>
                                <th>Plan</th>
                                <th>Montant</th>
                                <th>Taux / Jour</th>
                                <th>Statut</th>
                                <th>Date</th>
                            </tr>
                        </thead>
                        <tbody id="investments-list">
                            <tr><td colspan="5" class="text-center text-muted">Aucun investissement actif</td></tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <script>
        let currentUser = null;

        document.getElementById("register-form").addEventListener("submit", async (e) => {
            e.preventDefault();
            const nom = document.getElementById("reg-nom").value;
            const email = document.getElementById("reg-email").value;
            const telephone = document.getElementById("reg-phone").value;
            const password = document.getElementById("reg-password").value;

            const res = await fetch("/api/auth/register", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ nom, email, telephone, password })
            });
            const data = await res.json();
            if (res.ok) {
                alert("Compte créé avec succès ! Connectez-vous.");
            } else {
                alert(data.error);
            }
        });

        document.getElementById("login-form").addEventListener("submit", async (e) => {
            e.preventDefault();
            const email = document.getElementById("login-email").value;
            const password = document.getElementById("login-password").value;

            const res = await fetch("/api/auth/login", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ email, password })
            });
            const data = await res.json();
            if (res.ok) {
                currentUser = data.user;
                document.getElementById("auth-section").style.display = "none";
                document.getElementById("dashboard-section").style.display = "block";
                loadDashboardData();
            } else {
                alert(data.error);
            }
        });

        async function loadDashboardData() {
            if (!currentUser) return;
            
            const resBal = await fetch(\`/api/wallet/\${currentUser.id}\`);
            const dataBal = await resBal.json();
            if (resBal.ok) {
                document.getElementById("user-balance").innerText = \`\${parseFloat(dataBal.balance).toLocaleString()} FCFA\`;
            }

            const resInv = await fetch(\`/api/investment/user/\${currentUser.id}\`);
            const dataInv = await resInv.json();
            if (resInv.ok) {
                const tbody = document.getElementById("investments-list");
                tbody.innerHTML = "";
                if (dataInv.length === 0) {
                    tbody.innerHTML = "<tr><td colspan=\x225\x22 class=\x22text-center text-muted\x22>Aucun investissement actif</td></tr>";
                } else {
                    dataInv.forEach(inv => {
                        const row = \`<tr>
                            <td class="fw-bold">\${inv.plan_name}</td>
                            <td>\${parseFloat(inv.amount).toLocaleString()} FCFA</td>
                            <td class="text-success">+\${inv.daily_return_rate}%</td>
                            <td><span class="badge bg-success">\${inv.status}</span></td>
                            <td>\${new Date(inv.created_at).toLocaleDateString()}</td>
                        </tr>\`;
                        tbody.innerHTML += row;
                    });
                }
            }
        }

        async function depositMoney() {
            const amount = parseFloat(document.getElementById("deposit-amount").value);
            if (!amount || amount < 100) return alert("Saisissez un montant valide (minimum 100 FCFA)");

            const res = await fetch("/api/wallet/deposit", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ userId: currentUser.id, amount })
            });
            const data = await res.json();
            if (res.ok) {
                alert("Dépôt réussi !");
                document.getElementById("deposit-amount").value = "";
                loadDashboardData();
            } else {
                alert(data.error);
            }
        }

        async function invest(planName, amount, dailyReturnRate, durationDays) {
            if (!currentUser) return;
            const res = await fetch("/api/investment/subscribe", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ userId: currentUser.id, planName, amount, dailyReturnRate, durationDays })
            });
            const data = await res.json();
            if (res.ok) {
                alert(\`Souscription au \${planName} validée !\`);
                loadDashboardData();
            } else {
                alert(data.error);
            }
        }

        function logout() {
            currentUser = null;
            document.getElementById("auth-section").style.display = "flex";
            document.getElementById("dashboard-section").style.display = "none";
        }
    </script>
</body>
</html>`;
fs.writeFileSync("public/index.html", code);
console.log("Fichier mis à jour !");
'
node server.js
nano public/index.html
[200~node server.js~
node server.js
echo '<!DOCTYPE html><html lang="fr"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>InvestApp</title><link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet"><style>body{background-color:#f8f9fa;font-family:"Segoe UI",sans-serif}.hero{background:linear-gradient(135deg,#0d6efd,#0a58ca);color:white;padding:40px 0;border-radius:0 0 20px 20px}.card-custom{border:none;border-radius:15px;box-shadow:0 4px 15px rgba(0,0,0,0.05)}.btn-custom{border-radius:10px;font-weight:600;padding:10px 20px}</style></head><body><div class="hero text-center mb-4"><h1 class="fw-bold">InvestApp</h1><p class="lead">Faites fructifier vos économies simplement</p></div><div class="container" id="app"><div id="auth-section" class="row justify-content-center"><div class="col-md-5 mb-4"><div class="card card-custom p-4"><h3 class="text-center mb-3">Connexion</h3><form id="login-form"><div class="mb-3"><label class="form-label">Email</label><input type="email" id="login-email" class="form-control" required></div><div class="mb-3"><label class="form-label">Mot de passe</label><input type="password" id="login-password" class="form-control" required></div><button type="submit" class="btn btn-primary w-100 btn-custom">Se connecter</button></form></div></div><div class="col-md-5"><div class="card card-custom p-4"><h3 class="text-center mb-3">Créer un compte</h3><form id="register-form"><div class="mb-3"><label class="form-label">Nom complet</label><input type="text" id="reg-nom" class="form-control" required></div><div class="mb-3"><label class="form-label">Email</label><input type="email" id="reg-email" class="form-control" required></div><div class="mb-3"><label class="form-label">Téléphone</label><input type="text" id="reg-phone" class="form-control" required></div><div class="mb-3"><label class="form-label">Mot de passe</label><input type="password" id="reg-password" class="form-control" required></div><button type="submit" class="btn btn-success w-100 btn-custom">S"inscrire</button></form></div></div></div><div id="dashboard-section" style="display:none"><div class="row mb-4"><div class="col-md-12 text-end mb-2"><button class="btn btn-outline-danger btn-sm" onclick="logout()">Déconnexion</button></div><div class="col-md-6 mb-3"><div class="card card-custom p-4 text-center bg-white"><h5 class="text-muted">Solde Actuel</h5><h2 class="text-primary fw-bold" id="user-balance">0 FCFA</h2></div></div><div class="col-md-6 mb-3"><div class="card card-custom p-4 bg-white"><h5>Recharger le solde (Dépôt)</h5><div class="input-group mb-2"><input type="number" id="deposit-amount" class="form-control" placeholder="Montant en FCFA"><button class="btn btn-success" onclick="depositMoney()">Déposer</button></div></div></div></div><h4 class="mb-3">Plans d"Investissement Disponibles</h4><div class="row mb-4"><div class="col-md-3 mb-3"><div class="card card-custom p-3 text-center"><h5 class="fw-bold text-info">Plan Mini</h5><p class="h4">1 000 FCFA</p><p class="text-success fw-bold">+2.0% / jour (30 jours)</p><button class="btn btn-info text-white btn-custom" onclick="invest('"'Plan Mini'"', 1000, 2.0, 30)">Investir</button></div></div><div class="col-md-3 mb-3"><div class="card card-custom p-3 text-center"><h5 class="fw-bold text-primary">Plan Bronze</h5><p class="h4">5 000 FCFA</p><p class="text-success fw-bold">+2.5% / jour (30 jours)</p><button class="btn btn-primary btn-custom" onclick="invest('"'Plan Bronze'"', 5000, 2.5, 30)">Investir</button></div></div><div class="col-md-3 mb-3"><div class="card card-custom p-3 text-center"><h5 class="fw-bold text-warning">Plan Argent</h5><p class="h4">20 000 FCFA</p><p class="text-success fw-bold">+3.5% / jour (30 jours)</p><button class="btn btn-warning text-white btn-custom" onclick="invest('"'Plan Argent'"', 20000, 3.5, 30)">Investir</button></div></div><div class="col-md-3 mb-3"><div class="card card-custom p-3 text-center"><h5 class="fw-bold text-danger">Plan Or</h5><p class="h4">50 000 FCFA</p><p class="text-success fw-bold">+5.0% / jour (30 jours)</p><button class="btn btn-danger btn-custom" onclick="invest('"'Plan Or'"', 50000, 5.0, 30)">Investir</button></div></div></div><h4 class="mb-3">Mes Investissements en cours</h4><div class="card card-custom p-3 bg-white mb-4"><div class="table-responsive"><table class="table align-middle"><thead><tr><th>Plan</th><th>Montant</th><th>Taux / Jour</th><th>Statut</th><th>Date</th></tr></thead><tbody id="investments-list"><tr><td colspan="5" class="text-center text-muted">Aucun investissement actif</td></tr></tbody></table></div></div></div></div><script>let currentUser=null;document.getElementById("register-form").addEventListener("submit",async e=>{e.preventDefault();const nom=document.getElementById("reg-nom").value,email=document.getElementById("reg-email").value,telephone=document.getElementById("reg-phone").value,password=document.getElementById("reg-password").value;const res=await fetch("/api/auth/register",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({nom,email,telephone,password})});const data=await res.json();res.ok?alert("Compte créé avec succès ! Connectez-vous."):alert(data.error)});document.getElementById("login-form").addEventListener("submit",async e=>{e.preventDefault();const email=document.getElementById("login-email").value,password=document.getElementById("login-password").value;const res=await fetch("/api/auth/login",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({email,password})});const data=await res.json();res.ok?(currentUser=data.user,document.getElementById("auth-section").style.display="none",document.getElementById("dashboard-section").style.display="block",loadDashboardData()):alert(data.error)});async function loadDashboardData(){if(!currentUser)return;const resBal=await fetch(`/api/wallet/${currentUser.id}`),dataBal=await resBal.json();resBal.ok&&(document.getElementById("user-balance").innerText=`${parseFloat(dataBal.balance).toLocaleString()} FCFA`);const resInv=await fetch(`/api/investment/user/${currentUser.id}`),dataInv=await resInv.json();if(resInv.ok){const tbody=document.getElementById("investments-list");tbody.innerHTML="";if(dataInv.length===0)tbody.innerHTML="<tr><td colspan=\"5\" class=\"text-center text-muted\">Aucun investissement actif</td> innocent</td></tr>";else dataInv.forEach(inv=>{tbody.innerHTML+=`<tr><td class="fw-bold">${inv.plan_name}</td><td>${parseFloat(inv.amount).toLocaleString()} FCFA</td><td class="text-success">+${inv.daily_return_rate}%</td><td><span class="badge bg-success">${inv.status}</span></td><td>${new Date(inv.created_at).toLocaleDateString()}</td></tr>`})}}async function depositMoney(){const amount=parseFloat(document.getElementById("deposit-amount").value);if(!amount||amount<100)return alert("Saisissez un montant valide (minimum 100 FCFA)");const res=await fetch("/api/wallet/deposit",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({userId:currentUser.id,amount})});const data=await res.json();res.ok?(alert("Dépôt réussi !"),document.getElementById("deposit-amount").value="",loadDashboardData()):alert(data.error)}async function invest(planName,amount,dailyReturnRate,durationDays){if(!currentUser)return;const res=await fetch("/api/investment/subscribe",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({userId:currentUser.id,planName,amount,dailyReturnRate,durationDays})});const data=await res.json();res.ok?(alert(`Souscription au ${planName} validée !`),loadDashboardData()):alert(data.error)}function logout(){currentUser=null,document.getElementById("auth-section").style.display="flex",document.getElementById("dashboard-section").style.display="none"}</script></body></html>' > public/index.html
node server.js
cd ~/mon-site/invest-backend
echo '<!DOCTYPE html><html lang="fr"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>InvestApp</title><link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet"><style>body{background-color:#f8f9fa;font-family:"Segoe UI",sans-serif}.hero{background:linear-gradient(135deg,#0d6efd,#0a58ca);color:white;padding:40px 0;border-radius:0 0 20px 20px}.card-custom{border:none;border-radius:15px;box-shadow:0 4px 15px rgba(0,0,0,0.05)}.btn-custom{border-radius:10px;font-weight:600;padding:10px 20px}</style></head><body><div class="hero text-center mb-4"><h1 class="fw-bold">InvestApp</h1><p class="lead">Faites fructifier vos économies simplement</p></div><div class="container" id="app"><div id="auth-section" class="row justify-content-center"><div class="col-md-5 mb-4"><div class="card card-custom p-4"><h3 class="text-center mb-3">Connexion</h3><form id="login-form"><div class="mb-3"><label class="form-label">Email</label><input type="email" id="login-email" class="form-control" required></div><div class="mb-3"><label class="form-label">Mot de passe</label><input type="password" id="login-password" class="form-control" required></div><button type="submit" class="btn btn-primary w-100 btn-custom">Se connecter</button></form></div></div><div class="col-md-5"><div class="card card-custom p-4"><h3 class="text-center mb-3">Créer un compte</h3><form id="register-form"><div class="mb-3"><label class="form-label">Nom complet</label><input type="text" id="reg-nom" class="form-control" required></div><div class="mb-3"><label class="form-label">Email</label><input type="email" id="reg-email" class="form-control" required></div><div class="mb-3"><label class="form-label">Téléphone</label><input type="text" id="reg-phone" class="form-control" required></div><div class="mb-3"><label class="form-label">Mot de passe</label><input type="password" id="reg-password" class="form-control" required></div><button type="submit" class="btn btn-success w-100 btn-custom">S"inscrire</button></form></div></div></div><div id="dashboard-section" style="display:none"><div class="row mb-4"><div class="col-md-12 text-end mb-2"><button class="btn btn-outline-danger btn-sm" onclick="logout()">Déconnexion</button></div><div class="col-md-6 mb-3"><div class="card card-custom p-4 text-center bg-white"><h5 class="text-muted">Solde Actuel</h5><h2 class="text-primary fw-bold" id="user-balance">0 FCFA</h2></div></div><div class="col-md-6 mb-3"><div class="card card-custom p-4 bg-white"><h5>Recharger le solde (Dépôt)</h5><div class="input-group mb-2"><input type="number" id="deposit-amount" class="form-control" placeholder="Montant en FCFA"><button class="btn btn-success" onclick="depositMoney()">Déposer</button></div></div></div></div><h4 class="mb-3">Plans d"Investissement Disponibles</h4><div class="row mb-4"><div class="col-md-3 mb-3"><div class="card card-custom p-3 text-center"><h5 class="fw-bold text-info">Plan Mini</h5><p class="h4">1 000 FCFA</p><p class="text-success fw-bold">+2.0% / jour (30 jours)</p><button class="btn btn-info text-white btn-custom" onclick="invest('"'Plan Mini'"', 1000, 2.0, 30)">Investir</button></div></div><div class="col-md-3 mb-3"><div class="card card-custom p-3 text-center"><h5 class="fw-bold text-primary">Plan Bronze</h5><p class="h4">5 000 FCFA</p><p class="text-success fw-bold">+2.5% / jour (30 jours)</p><button class="btn btn-primary btn-custom" onclick="invest('"'Plan Bronze'"', 5000, 2.5, 30)">Investir</button></div></div><div class="col-md-3 mb-3"><div class="card card-custom p-3 text-center"><h5 class="fw-bold text-warning">Plan Argent</h5><p class="h4">20 000 FCFA</p><p class="text-success fw-bold">+3.5% / jour (30 jours)</p><button class="btn btn-warning text-white btn-custom" onclick="invest('"'Plan Argent'"', 20000, 3.5, 30)">Investir</button></div></div><div class="col-md-3 mb-3"><div class="card card-custom p-3 text-center"><h5 class="fw-bold text-danger">Plan Or</h5><p class="h4">50 000 FCFA</p><p class="text-success fw-bold">+5.0% / jour (30 jours)</p><button class="btn btn-danger btn-custom" onclick="invest('"'Plan Or'"', 50000, 5.0, 30)">Investir</button></div></div></div><h4 class="mb-3">Mes Investissements en cours</h4><div class="card card-custom p-3 bg-white mb-4"><div class="table-responsive"><table class="table align-middle"><thead><tr><th>Plan</th><th>Montant</th><th>Taux / Jour</th><th>Statut</th><th>Date</th></tr></thead><tbody id="investments-list"><tr><td colspan="5" class="text-center text-muted">Aucun investissement actif</td></tr></tbody></table></div></div></div></div><script>let currentUser=null;document.getElementById("register-form").addEventListener("submit",async e=>{e.preventDefault();const nom=document.getElementById("reg-nom").value,email=document.getElementById("reg-email").value,telephone=document.getElementById("reg-phone").value,password=document.getElementById("reg-password").value;const res=await fetch("/api/auth/register",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({nom,email,telephone,password})});const data=await res.json();res.ok?alert("Compte créé avec succès ! Connectez-vous."):alert(data.error)});document.getElementById("login-form").addEventListener("submit",async e=>{e.preventDefault();const email=document.getElementById("login-email").value,password=document.getElementById("login-password").value;const res=await fetch("/api/auth/login",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({email,password})});const data=await res.json();res.ok?(currentUser=data.user,document.getElementById("auth-section").style.display="none",document.getElementById("dashboard-section").style.display="block",loadDashboardData()):alert(data.error)});async function loadDashboardData(){if(!currentUser)return;const resBal=await fetch(`/api/wallet/${currentUser.id}`),dataBal=await resBal.json();resBal.ok&&(document.getElementById("user-balance").innerText=`${parseFloat(dataBal.balance).toLocaleString()} FCFA`);const resInv=await fetch(`/api/investment/user/${currentUser.id}`),dataInv=await resInv.json();if(resInv.ok){const tbody=document.getElementById("investments-list");tbody.innerHTML="";if(dataInv.length===0)tbody.innerHTML="<tr><td colspan=\"5\" class=\"text-center text-muted\">Aucun investissement actif</td></tr>";else dataInv.forEach(inv=>{tbody.innerHTML+=`<tr><td class="fw-bold">${inv.plan_name}</td><td>${parseFloat(inv.amount).toLocaleString()} FCFA</td><td class="text-success">+${inv.daily_return_rate}%</td><td><span class="badge bg-success">${inv.status}</span></td><td>${new Date(inv.created_at).toLocaleDateString()}</td></tr>`})}}async function depositMoney(){const amount=parseFloat(document.getElementById("deposit-amount").value);if(!amount||amount<100)return alert("Saisissez un montant valide (minimum 100 FCFA)");const res=await fetch("/api/wallet/deposit",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({userId:currentUser.id,amount})});const data=await res.json();res.ok?(alert("Dépôt réussi !"),document.getElementById("deposit-amount").value="",loadDashboardData()):alert(data.error)}async function invest(planName,amount,dailyReturnRate,durationDays){if(!currentUser)return;const res=await fetch("/api/investment/subscribe",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({userId:currentUser.id,planName,amount,dailyReturnRate,durationDays})});const data=await res.json();res.ok?(alert(`Souscription au ${planName} validée !`),loadDashboardData()):alert(data.error)}function logout(){currentUser=null,document.getElementById("auth-section").style.display="flex",document.getElementById("dashboard-section").style.display="none"}</script></body></html>' > public/index.html
node server.js
npm install fedapay
cd nom-de-ton-dossier
ls
cd mon-site
npm start
ls
cd invest-backend
node server.js
nano .env
node server.js
cd ..
nano index.html
cd invest-backend
node server.js
nano index.html
cd ..
nano index.html
grep -rn "100 FCFA" .
nano index.html
cd invest-backend
node server.js
nano invest-backend/public/index.html
nano invest-backend/index.html
nano invest-backend/index.htm
nano invest-backend/index.html
nano index.html
cd ~/invest-backend
nano index.html
cd..
cd ..
cd invest-backend
nano index.html
nano public/index.html
node server.js
nano server.js
nano wallet.js
node server.js
nano public/index.html
node server.js
nano public/index.html
node server.js
nano public/index.html
node server.js
nano server.js
nano wallet.js
node server.js
nano wallet.js
node server.js
nano wallet.js
node server.js
nano wallet.js
node server.js
nano wallet.js
nano server.js
node server.js
nano admin.html
node server.js
nano admin.html
node server.js
npx localtunnel --port 8000
node server.js
nano server.js
