const { isFutureDate, canCancelBooking, formatServiceName } = require('./bookingHelpers');

describe('bookingHelpers', () => {
  it('detecta fechas futuras', () => {
    const future = new Date(Date.now() + 86400000).toISOString();
    expect(isFutureDate(future)).toBe(true);
  });

  it('permite cancelar reserva activa futura', () => {
    expect(canCancelBooking({
      estado: 'activa',
      fecha: new Date(Date.now() + 86400000).toISOString(),
    })).toBe(true);
  });

  it('normaliza nombre de servicio', () => {
    expect(formatServiceName('  Hotel   Deluxe  ')).toBe('Hotel Deluxe');
  });
});
