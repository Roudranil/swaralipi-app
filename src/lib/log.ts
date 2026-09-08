/** Thin `console` wrapper gated on dev builds, per CLAUDE.md's "no bare console in feature code" rule. */

/** Logs an error with context. No-op in production builds. */
export function logError(message: string, error: unknown): void {
  if (import.meta.env.DEV) {
    console.error(message, error);
  }
}
