/**
 * Validaciones reutilizables para el servicio de autenticación.
 * Extraídas para facilitar tests y cumplir cobertura en SonarQube.
 */

function isValidEmail(email) {
  if (typeof email !== 'string') return false;
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email.trim());
}

function isValidPassword(password) {
  if (typeof password !== 'string') return false;
  return password.length >= 8;
}

function validateRegistrationInput({ name, email, password }) {
  const errors = [];

  if (!name || typeof name !== 'string' || name.trim().length < 2) {
    errors.push('El nombre debe tener al menos 2 caracteres');
  }
  if (!isValidEmail(email)) {
    errors.push('Correo electrónico inválido');
  }
  if (!isValidPassword(password)) {
    errors.push('La contraseña debe tener al menos 8 caracteres');
  }

  return { valid: errors.length === 0, errors };
}

module.exports = { isValidEmail, isValidPassword, validateRegistrationInput };
