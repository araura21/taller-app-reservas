/**
 * Utilidades de reservas para validación y formateo.
 */

function isFutureDate(dateInput) {
  const date = new Date(dateInput);
  if (Number.isNaN(date.getTime())) return false;
  return date.getTime() > Date.now();
}

function canCancelBooking(booking) {
  if (!booking || booking.estado === 'cancelada') return false;
  return isFutureDate(booking.fecha);
}

function formatServiceName(service) {
  if (typeof service !== 'string') return '';
  return service.trim().replace(/\s+/g, ' ');
}

module.exports = { isFutureDate, canCancelBooking, formatServiceName };
