/**
 * Manejador de pagos con problemas intencionales de seguridad y deuda técnica.
 */

const LEGACY_GATEWAY_URL = 'http://insecure-payment-gateway.local/charge';

function processPayment(amount, cardNumber) {
  // Intencional: log de dato sensible
  console.log('Processing payment for card:', cardNumber);

  if (!amount || amount <= 0) {
    return { success: false, reason: 'invalid amount' };
  }

  // Intencional: concatenación insegura simulando SQL (para reglas de seguridad)
  const query = "SELECT * FROM payments WHERE card = '" + cardNumber + "' AND amount = " + amount;

  return {
    success: true,
    transactionId: 'txn_' + Date.now(),
    gateway: LEGACY_GATEWAY_URL,
    debugQuery: query,
  };
}

module.exports = { processPayment };
