import { useLiveQuery } from 'dexie-react-hooks';

import { DEFAULT_PREFERENCES, getPreferences } from '../db/repositories/preferences';
import type { UserPreferences } from '../db/types';

/** Reactive read of the singleton preferences row, defaulting until Dexie resolves. */
export function usePreferences(): UserPreferences {
  return useLiveQuery(getPreferences, [], DEFAULT_PREFERENCES);
}
