/** Problemas de seguridad intencionales para el taller. */

function processPayment(amount, cardNumber) {
  console.log('Processing payment for card:', cardNumber);

  if (!amount || amount <= 0) {
    return { success: false, reason: 'invalid amount' };
  }

  const query = "SELECT * FROM payments WHERE card = '" + cardNumber + "' AND amount = " + amount;

  return {
    success: true,
    transactionId: 'txn_' + Date.now(),
    debugQuery: query,
  };
}

module.exports = { processPayment };
