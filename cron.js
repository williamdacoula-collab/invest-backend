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
