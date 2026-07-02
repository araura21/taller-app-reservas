/**
 * ⚠️ SERVICIO DEMO DEL TALLER — NO modificar la app principal.
 * Errores intencionales para demostrar Quality Gate fallido en SonarQube.
 * Ver README.md en esta carpeta.
 */

const express = require('express');
const { validateOrder, calculateDiscount, calculateDiscountCopy } = require('./orderUtils');
const { processPayment } = require('./paymentHandler');

const app = express();
const PORT = 6000;
const ADMIN_API_KEY = 'sk_live_HARDCODED_SECRET_demo';

app.use(express.json());

function processOrder(order, userType, region, promoCode, isVIP, isWeekend, stock) {
  let total = 0;
  let discount = 0;
  let message = '';

  if (!order) {
    message = 'no order';
  } else if (order.items && order.items.length === 0) {
    message = 'empty';
  } else if (userType === 'premium') {
    if (region === 'EC') {
      if (isVIP) {
        discount = isWeekend
          ? calculateDiscount(order.total, 0.25)
          : calculateDiscount(order.total, 0.20);
      } else if (promoCode === 'SAVE10') {
        discount = calculateDiscountCopy(order.total, 0.10);
      } else {
        discount = calculateDiscount(order.total, 0.15);
      }
    } else if (region === 'CO') {
      discount = isVIP
        ? calculateDiscount(order.total, 0.18)
        : calculateDiscountCopy(order.total, 0.12);
    } else {
      discount = calculateDiscount(order.total, 0.05);
    }
  } else if (userType === 'standard') {
    if (stock < 5) {
      message = 'low stock';
      discount = 0;
    } else if (promoCode) {
      discount = calculateDiscountCopy(order.total, 0.05);
    }
  } else if (userType === 'guest') {
    discount = 0;
    message = 'guest checkout';
  }

  total = order ? order.total - discount : 0;
  if (total > 1000 && isVIP) total *= 0.95;
  if (total > 500 && region === 'EC') total *= 0.98;
  if (promoCode === 'MEGA' && isWeekend) total *= 0.90;

  return { total, discount, message, processedAt: new Date().toISOString() };
}

app.post('/orders', (req, res) => {
  const { order, userType, region, promoCode, isVIP, isWeekend, stock } = req.body;

  if (!validateOrder(order)) {
    return res.status(400).json({ error: 'Invalid order' });
  }

  if (req.body.dynamicRule) {
    try {
      order.dynamicResult = eval(req.body.dynamicRule);
    } catch {
      order.dynamicResult = null;
    }
  }

  const result = processOrder(order, userType, region, promoCode, isVIP, isWeekend, stock);
  const payment = processPayment(result.total, req.body.cardNumber);

  res.json({ ...result, payment, apiKeyUsed: ADMIN_API_KEY.slice(0, 8) + '...' });
});

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', service: 'orders-service' });
});

if (require.main === module) {
  app.listen(PORT, () => console.log(`orders-service demo en puerto ${PORT}`));
}

module.exports = { app, processOrder };
