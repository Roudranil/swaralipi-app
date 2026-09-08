import { describe, expect, it } from 'vitest';

import { MAX_NAME_LENGTH, titleCaseName, validateName } from './nameField';

describe('validateName', () => {
  it('accepts an empty draft — no name set means a plain "Hi"', () => {
    expect(validateName('')).toEqual({ valid: true });
    expect(validateName('   ')).toEqual({ valid: true });
  });

  it('accepts a single word of letters, including non-Latin scripts', () => {
    expect(validateName('Roudranil')).toEqual({ valid: true });
    expect(validateName('রুদ্রনীল')).toEqual({ valid: true });
    expect(validateName('रुद्रनील')).toEqual({ valid: true });
  });

  it('rejects internal whitespace (more than one word)', () => {
    expect(validateName('Roudranil Deb')).toEqual({ valid: false, error: 'One word, letters only.' });
  });

  it('rejects digits and symbols', () => {
    expect(validateName('Rou4ranil')).toEqual({ valid: false, error: 'One word, letters only.' });
    expect(validateName('Roudranil!')).toEqual({ valid: false, error: 'One word, letters only.' });
  });

  it('rejects a draft over the max length', () => {
    const tooLong = 'a'.repeat(MAX_NAME_LENGTH + 1);
    expect(validateName(tooLong)).toEqual({
      valid: false,
      error: `Keep it under ${MAX_NAME_LENGTH} characters.`,
    });
  });

  it('accepts a draft at exactly the max length', () => {
    const exact = 'a'.repeat(MAX_NAME_LENGTH);
    expect(validateName(exact)).toEqual({ valid: true });
  });
});

describe('titleCaseName', () => {
  it('uppercases the first letter and lowercases the rest', () => {
    expect(titleCaseName('roudranil')).toBe('Roudranil');
    expect(titleCaseName('ROUDRANIL')).toBe('Roudranil');
    expect(titleCaseName('rOUDRANIL')).toBe('Roudranil');
  });

  it('trims surrounding whitespace', () => {
    expect(titleCaseName('  roudranil  ')).toBe('Roudranil');
  });

  it('returns an empty string for an empty or blank draft', () => {
    expect(titleCaseName('')).toBe('');
    expect(titleCaseName('   ')).toBe('');
  });
});
