const { isValidEmail, isValidPassword, validateRegistrationInput } = require('./validation');

describe('validation utils', () => {
  it('acepta emails válidos', () => {
    expect(isValidEmail('user@example.com')).toBe(true);
  });

  it('rechaza emails inválidos', () => {
    expect(isValidEmail('bad')).toBe(false);
  });

  it('valida registro completo', () => {
    const result = validateRegistrationInput({
      name: 'Ana', email: 'ana@test.com', password: 'password123',
    });
    expect(result.valid).toBe(true);
  });
});
