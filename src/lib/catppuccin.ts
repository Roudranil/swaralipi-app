/** Catppuccin Mocha (dark) and Latte (light) palettes. See docs/design-system.md §4. */

export type CatppuccinSwatchName =
  | 'rosewater'
  | 'flamingo'
  | 'pink'
  | 'mauve'
  | 'red'
  | 'maroon'
  | 'peach'
  | 'yellow'
  | 'green'
  | 'teal'
  | 'sky'
  | 'sapphire'
  | 'blue'
  | 'lavender'
  | 'text';

/** Display order for the seed-color swatch grid. */
export const SWATCH_NAMES: readonly CatppuccinSwatchName[] = [
  'rosewater',
  'flamingo',
  'pink',
  'mauve',
  'red',
  'maroon',
  'peach',
  'yellow',
  'green',
  'teal',
  'sky',
  'sapphire',
  'blue',
  'lavender',
  'text',
];

export const SWATCH_LABELS: Record<CatppuccinSwatchName, string> = {
  rosewater: 'Rosewater',
  flamingo: 'Flamingo',
  pink: 'Pink',
  mauve: 'Mauve',
  red: 'Red',
  maroon: 'Maroon',
  peach: 'Peach',
  yellow: 'Yellow',
  green: 'Green',
  teal: 'Teal',
  sky: 'Sky',
  sapphire: 'Sapphire',
  blue: 'Blue',
  lavender: 'Lavender',
  text: 'Text',
};

export const CATPPUCCIN_MOCHA: Record<CatppuccinSwatchName, string> = {
  rosewater: '#F5E0DC',
  flamingo: '#F2CDCD',
  pink: '#F5C2E7',
  mauve: '#CBA6F7',
  red: '#F38BA8',
  maroon: '#EBA0AC',
  peach: '#FAB387',
  yellow: '#F9E2AF',
  green: '#A6E3A1',
  teal: '#94E2D5',
  sky: '#89DCEB',
  sapphire: '#74C7EC',
  blue: '#89B4FA',
  lavender: '#B4BEFE',
  text: '#CDD6F4',
};

export const CATPPUCCIN_LATTE: Record<CatppuccinSwatchName, string> = {
  rosewater: '#DC8A78',
  flamingo: '#DD7878',
  pink: '#EA76CB',
  mauve: '#8839EF',
  red: '#D20F39',
  maroon: '#E64553',
  peach: '#FE640B',
  yellow: '#DF8E1D',
  green: '#40A02B',
  teal: '#179299',
  sky: '#04A5E5',
  sapphire: '#209FB5',
  blue: '#1E66F5',
  lavender: '#7287FD',
  text: '#4C4F69',
};

export const DEFAULT_SEED_SWATCH: CatppuccinSwatchName = 'mauve';

/** The hex a `theme.ts` `applyTheme()` call needs for each mode, resolved from one swatch name. */
export interface ThemeSeeds {
  readonly lightSeedHex: string;
  readonly darkSeedHex: string;
}

/**
 * Resolves a stored swatch name into the light (Latte) and dark (Mocha) hex
 * pair. This is the single place that bridges "one user choice" to "two
 * token sets" — see docs/design-system.md §4.
 */
export function swatchSeeds(name: CatppuccinSwatchName): ThemeSeeds {
  return {
    lightSeedHex: CATPPUCCIN_LATTE[name],
    darkSeedHex: CATPPUCCIN_MOCHA[name],
  };
}
