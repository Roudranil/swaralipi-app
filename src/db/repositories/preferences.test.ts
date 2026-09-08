import { afterEach, describe, expect, it } from 'vitest';

import { db } from '../db';
import { DEFAULT_PREFERENCES, ensurePreferences, getPreferences, updatePreferences } from './preferences';
import { CATPPUCCIN_LATTE, CATPPUCCIN_MOCHA, swatchSeeds } from '../../lib/catppuccin';

afterEach(async () => {
  await db.preferences.clear();
});

describe('getPreferences', () => {
  it('returns the defaults without writing a row when the table is empty', async () => {
    const result = await getPreferences();

    expect(result).toEqual(DEFAULT_PREFERENCES);
    expect(await db.preferences.get(1)).toBeUndefined();
  });
});

describe('ensurePreferences', () => {
  it('writes the default row when none exists', async () => {
    await ensurePreferences();

    expect(await db.preferences.get(1)).toEqual(DEFAULT_PREFERENCES);
  });

  it('is idempotent, never clobbering an already-edited row', async () => {
    await ensurePreferences();
    await updatePreferences({ seedColor: 'green' });

    await ensurePreferences();

    expect((await db.preferences.get(1))?.seedColor).toBe('green');
  });
});

describe('updatePreferences', () => {
  it('round-trips a patch, leaving other fields intact', async () => {
    await updatePreferences({ themeMode: 'dark' });

    const result = await getPreferences();

    expect(result.themeMode).toBe('dark');
    expect(result.seedColor).toBe(DEFAULT_PREFERENCES.seedColor);
    expect(result.userName).toBe(DEFAULT_PREFERENCES.userName);
  });
});

describe('swatchSeeds', () => {
  it('resolves a swatch name to its Latte (light) and Mocha (dark) hexes', () => {
    expect(swatchSeeds('mauve')).toEqual({
      lightSeedHex: CATPPUCCIN_LATTE.mauve,
      darkSeedHex: CATPPUCCIN_MOCHA.mauve,
    });
  });
});
