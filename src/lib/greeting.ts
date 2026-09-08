/**
 * Formats the Library screen's hero greeting from the personalisation name.
 * Shared with the Personalisation screen's live preview so the two can
 * never disagree on what the greeting looks like.
 */
export function greeting(userName: string): string {
  const trimmed = userName.trim();
  return trimmed === '' ? 'Hi' : `Hi, ${trimmed}`;
}
