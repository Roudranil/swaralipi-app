import { usePreferences } from './usePreferences';
import { useResolvedThemeMode } from './useResolvedThemeMode';
import { CATPPUCCIN_LATTE, CATPPUCCIN_MOCHA, type CatppuccinSwatchName } from '../lib/catppuccin';

export interface ResolvedCatppuccinPalette {
  readonly colors: Record<CatppuccinSwatchName, string>;
  /**
   * Contrasting text color for any hex in `colors` — every Latte hex is dark
   * enough for white text and every Mocha hex is light enough for black,
   * same reasoning `SwatchGrid` uses for its check mark.
   */
  readonly onColorClassName: 'text-white' | 'text-black';
}

/**
 * Resolves the Catppuccin Latte/Mocha palette actually painted right now,
 * for UI that needs a *fixed* semantic color (a destructive or affirmative
 * pill) rather than the user's chosen accent seed. See docs/design-system.md §4.
 */
export function useCatppuccinPalette(): ResolvedCatppuccinPalette {
  const { themeMode } = usePreferences();
  const resolvedMode = useResolvedThemeMode(themeMode);
  return {
    colors: resolvedMode === 'light' ? CATPPUCCIN_LATTE : CATPPUCCIN_MOCHA,
    onColorClassName: resolvedMode === 'light' ? 'text-white' : 'text-black',
  };
}
