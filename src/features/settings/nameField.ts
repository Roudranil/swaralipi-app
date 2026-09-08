/** Pure validation/formatting rules for the Personalisation "Your name" field. */

export const MAX_NAME_LENGTH = 24;

// `\p{M}` (combining marks) is required alongside `\p{L}` for scripts like
// Bengali/Devanagari, where vowel signs and virama are their own combining
// codepoints rather than part of the base letter. This also rejects internal
// whitespace, which doubles as the "one word" rule.
const LETTERS_ONLY = /^[\p{L}\p{M}]+$/u;

export type NameValidation = { readonly valid: true } | { readonly valid: false; readonly error: string };

/**
 * Validates a name draft. Empty is valid — it means "no name set", and the
 * Library greeting falls back to a plain "Hi" (`src/lib/greeting.ts`).
 */
export function validateName(draft: string): NameValidation {
  const trimmed = draft.trim();
  if (trimmed === '') return { valid: true };
  if (trimmed.length > MAX_NAME_LENGTH) {
    return { valid: false, error: `Keep it under ${MAX_NAME_LENGTH} characters.` };
  }
  if (!LETTERS_ONLY.test(trimmed)) {
    return { valid: false, error: 'One word, letters only.' };
  }
  return { valid: true };
}

/**
 * Title-cases a single word: uppercases the first letter, lowercases the
 * rest. Applied on blur, not per keystroke, so it doesn't fight the caret
 * mid-word.
 */
export function titleCaseName(draft: string): string {
  const trimmed = draft.trim();
  if (trimmed === '') return '';
  return trimmed[0].toUpperCase() + trimmed.slice(1).toLowerCase();
}
