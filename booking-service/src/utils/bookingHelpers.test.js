const { isFutureDate, canCancelBooking, formatServiceName } = require('./bookingHelpers');

describe('bookingHelpers', () => {
  describe('isFutureDate', () => {
    it('detecta fechas futuras', () => {
      const future = new Date(Date.now() + 86400000).toISOString();
      expect(isFutureDate(future)).toBe(true);
    });

    it('rechaza fechas pasadas', () => {
      expect(isFutureDate('2020-01-01')).toBe(false);
    });
  });

  describe('canCancelBooking', () => {
    it('permite cancelar reserva activa futura', () => {
      const booking = {
        estado: 'activa',
        fecha: new Date(Date.now() + 86400000).toISOString(),
      };
      expect(canCancelBooking(booking)).toBe(true);
    });

    it('no permite cancelar reserva ya cancelada', () => {
      expect(canCancelBooking({ estado: 'cancelada', fecha: new Date() })).toBe(false);
    });
  });

  describe('formatServiceName', () => {
    it('normaliza espacios', () => {
      expect(formatServiceName('  Hotel   Deluxe  ')).toBe('Hotel Deluxe');
    });
  });
});
