/**
 * Synchronous localStorage mirror of the theme prefs, used only for the very
 * first paint. `applyTheme()`/`applyThemeMode()` run before `createRoot()`
 * in `main.tsx`, while the real source of truth — the `preferences` Dexie
 * table — can only be read asynchronously. Without this mirror, a dark-mode
 * user would see a full-screen light flash on every cold start.
 *
 * Dexie stays authoritative: `useAppliedTheme()` re-applies from `preferences`
 * on every render and calls `writeBootTheme()` to keep this mirror current.
 */

import { DEFAULT_SEED_SWATCH, SWATCH_NAMES, type CatppuccinSwatchName } from './catppuccin';
import type { ThemeMode } from '../db/types';

const STORAGE_KEY = 'swaralipi.theme';
const THEME_MODES: readonly ThemeMode[] = ['light', 'dark', 'system'];

export interface BootTheme {
  readonly mode: ThemeMode;
  readonly seed: CatppuccinSwatchName;
}

const DEFAULT_BOOT_THEME: BootTheme = {
  mode: 'system',
  seed: DEFAULT_SEED_SWATCH,
};

const isThemeMode = (value: unknown): value is ThemeMode =>
  typeof value === 'string' && THEME_MODES.includes(value as ThemeMode);

const isSwatchName = (value: unknown): value is CatppuccinSwatchName =>
  typeof value === 'string' && SWATCH_NAMES.includes(value as CatppuccinSwatchName);

/** Reads the cached theme, falling back to defaults on missing or malformed data. */
export function readBootTheme(): BootTheme {
  const raw = localStorage.getItem(STORAGE_KEY);
  if (!raw) return DEFAULT_BOOT_THEME;

  try {
    const parsed: unknown = JSON.parse(raw);
    if (typeof parsed !== 'object' || parsed === null) return DEFAULT_BOOT_THEME;

    const { mode, seed } = parsed as Record<string, unknown>;
    return {
      mode: isThemeMode(mode) ? mode : DEFAULT_BOOT_THEME.mode,
      seed: isSwatchName(seed) ? seed : DEFAULT_BOOT_THEME.seed,
    };
  } catch {
    return DEFAULT_BOOT_THEME;
  }
}

/** Caches the current theme choice for next cold start's first paint. */
export function writeBootTheme(mode: ThemeMode, seed: CatppuccinSwatchName): void {
  localStorage.setItem(STORAGE_KEY, JSON.stringify({ mode, seed }));
}
