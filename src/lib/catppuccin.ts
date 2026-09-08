/** Catppuccin Mocha (dark) and Latte (light) palettes. See docs/design-system.md §2. */

export interface CatppuccinSwatch {
  name: string;
  hex: string;
}

export const CATPPUCCIN_MOCHA: CatppuccinSwatch[] = [
  { name: 'Rosewater', hex: '#F5E0DC' },
  { name: 'Flamingo', hex: '#F2CDCD' },
  { name: 'Pink', hex: '#F5C2E7' },
  { name: 'Mauve', hex: '#CBA6F7' },
  { name: 'Red', hex: '#F38BA8' },
  { name: 'Maroon', hex: '#EBA0AC' },
  { name: 'Peach', hex: '#FAB387' },
  { name: 'Yellow', hex: '#F9E2AF' },
  { name: 'Green', hex: '#A6E3A1' },
  { name: 'Teal', hex: '#94E2D5' },
  { name: 'Sky', hex: '#89DCEB' },
  { name: 'Sapphire', hex: '#74C7EC' },
  { name: 'Blue', hex: '#89B4FA' },
  { name: 'Lavender', hex: '#B4BEFE' },
  { name: 'Text', hex: '#CDD6F4' },
];

export const CATPPUCCIN_LATTE: CatppuccinSwatch[] = [
  { name: 'Rosewater', hex: '#DC8A78' },
  { name: 'Flamingo', hex: '#DD7878' },
  { name: 'Pink', hex: '#EA76CB' },
  { name: 'Mauve', hex: '#8839EF' },
  { name: 'Red', hex: '#D20F39' },
  { name: 'Maroon', hex: '#E64553' },
  { name: 'Peach', hex: '#FE640B' },
  { name: 'Yellow', hex: '#DF8E1D' },
  { name: 'Green', hex: '#40A02B' },
  { name: 'Teal', hex: '#179299' },
  { name: 'Sky', hex: '#04A5E5' },
  { name: 'Sapphire', hex: '#209FB5' },
  { name: 'Blue', hex: '#1E66F5' },
  { name: 'Lavender', hex: '#7287FD' },
  { name: 'Text', hex: '#4C4F69' },
];

export const DEFAULT_SEED_DARK = '#CBA6F7'; // Mocha Mauve
export const DEFAULT_SEED_LIGHT = '#8839EF'; // Latte Mauve
