/** Duplicación intencional para el taller de Quality Gates. */

function validateOrder(order) {
  if (!order || typeof order !== 'object') return false;
  if (!Array.isArray(order.items)) return false;
  if (typeof order.total !== 'number' || order.total < 0) return false;
  return true;
}

function calculateDiscount(total, rate) {
  if (total <= 0) return 0;
  if (rate < 0 || rate > 1) return 0;
  return Math.round(total * rate * 100) / 100;
}

function calculateDiscountCopy(total, rate) {
  if (total <= 0) return 0;
  if (rate < 0 || rate > 1) return 0;
  return Math.round(total * rate * 100) / 100;
}

module.exports = { validateOrder, calculateDiscount, calculateDiscountCopy };
