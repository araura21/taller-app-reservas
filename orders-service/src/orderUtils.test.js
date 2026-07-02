const { validateOrder, calculateDiscount } = require('./orderUtils');

describe('orderUtils', () => {
  it('rechaza orden nula', () => {
    expect(validateOrder(null)).toBe(false);
  });

  it('acepta orden válida', () => {
    expect(validateOrder({ items: [{ id: 1 }], total: 100 })).toBe(true);
  });

  it('calcula descuento', () => {
    expect(calculateDiscount(200, 0.1)).toBe(20);
  });
});
