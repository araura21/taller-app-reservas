const { validateOrder, calculateDiscount } = require('./orderUtils');

describe('orderUtils', () => {
  describe('validateOrder', () => {
    it('rechaza orden nula', () => {
      expect(validateOrder(null)).toBe(false);
    });

    it('acepta orden válida', () => {
      expect(validateOrder({ items: [{ id: 1 }], total: 100 })).toBe(true);
    });
  });

  describe('calculateDiscount', () => {
    it('calcula descuento correctamente', () => {
      expect(calculateDiscount(200, 0.1)).toBe(20);
    });

    it('retorna 0 para total inválido', () => {
      expect(calculateDiscount(-1, 0.1)).toBe(0);
    });
  });
});
