const { isValidEmail, isValidPassword, validateRegistrationInput } = require('./validation');

describe('validation utils', () => {
  describe('isValidEmail', () => {
    it('acepta emails válidos', () => {
      expect(isValidEmail('user@example.com')).toBe(true);
    });

    it('rechaza emails inválidos', () => {
      expect(isValidEmail('not-an-email')).toBe(false);
      expect(isValidEmail('')).toBe(false);
    });
  });

  describe('isValidPassword', () => {
    it('requiere mínimo 8 caracteres', () => {
      expect(isValidPassword('12345678')).toBe(true);
      expect(isValidPassword('short')).toBe(false);
    });
  });

  describe('validateRegistrationInput', () => {
    it('valida datos completos correctamente', () => {
      const result = validateRegistrationInput({
        name: 'Ana',
        email: 'ana@test.com',
        password: 'password123',
      });
      expect(result.valid).toBe(true);
      expect(result.errors).toHaveLength(0);
    });

    it('reporta múltiples errores', () => {
      const result = validateRegistrationInput({
        name: 'A',
        email: 'bad',
        password: '123',
      });
      expect(result.valid).toBe(false);
      expect(result.errors.length).toBeGreaterThan(0);
    });
  });
});
