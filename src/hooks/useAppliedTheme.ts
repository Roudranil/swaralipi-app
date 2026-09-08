import { useEffect } from 'react';

import { usePreferences } from './usePreferences';
import { ensurePreferences } from '../db/repositories/preferences';
import { swatchSeeds } from '../lib/catppuccin';
import { applyTheme, applyThemeMode } from '../lib/theme';
import { writeBootTheme } from '../lib/themeBoot';
import { logError } from '../lib/log';

/**
 * Reconciles the DOM theme with the `preferences` table: re-applies the M3
 * tokens and `mdui-theme-*` class whenever `themeMode`/`seedColor` change,
 * and refreshes the localStorage boot cache (`src/lib/themeBoot.ts`) so the
 * next cold start paints correctly before Dexie has loaded.
 *
 * Also seeds the singleton preferences row on first mount if it's missing.
 */
export function useAppliedTheme(): void {
  const preferences = usePreferences();
  const { themeMode, seedColor } = preferences;

  useEffect(() => {
    ensurePreferences().catch((error: unknown) => {
      logError('failed to seed default preferences', error);
    });
  }, []);

  useEffect(() => {
    applyTheme(swatchSeeds(seedColor));
    applyThemeMode(themeMode);
    writeBootTheme(themeMode, seedColor);
  }, [themeMode, seedColor]);
}
