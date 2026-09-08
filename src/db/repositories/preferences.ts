import { db } from '../db';
import { DEFAULT_SEED_SWATCH } from '../../lib/catppuccin';
import type { UserPreferences } from '../types';

/** Singleton row used until `ensurePreferences()` has written the real one. */
export const DEFAULT_PREFERENCES: UserPreferences = {
  id: 1,
  userName: '',
  themeMode: 'system',
  colorSchemeMode: 'catppuccin',
  seedColor: DEFAULT_SEED_SWATCH,
  defaultSort: 'createdAtDesc',
  defaultView: 'list',
};

/**
 * Reads the singleton preferences row, falling back to defaults if it has
 * never been written. Never writes — safe to use directly as a
 * `useLiveQuery` query function.
 */
export async function getPreferences(): Promise<UserPreferences> {
  const existing = await db.preferences.get(1);
  return existing ?? DEFAULT_PREFERENCES;
}

/** Writes the default singleton row if it doesn't exist yet. Call once at boot. */
export async function ensurePreferences(): Promise<void> {
  const existing = await db.preferences.get(1);
  if (existing === undefined) {
    await db.preferences.add(DEFAULT_PREFERENCES);
  }
}

/**
 * Merges `patch` into the singleton preferences row and writes it back.
 * Works even before `ensurePreferences()` has run, since it reads-through
 * to the same defaults `getPreferences()` uses.
 */
export async function updatePreferences(
  patch: Partial<Omit<UserPreferences, 'id'>>,
): Promise<void> {
  const current = await getPreferences();
  await db.preferences.put({ ...current, ...patch });
}
