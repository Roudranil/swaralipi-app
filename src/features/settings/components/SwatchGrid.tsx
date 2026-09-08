import type { ReactElement } from 'react';

import { Icon } from '../../../components/Icon';
import {
  CATPPUCCIN_LATTE,
  CATPPUCCIN_MOCHA,
  SWATCH_LABELS,
  SWATCH_NAMES,
  type CatppuccinSwatchName,
} from '../../../lib/catppuccin';

type SwatchGridProps = {
  readonly selected: CatppuccinSwatchName;
  /** Which palette (Latte/Mocha) is actually painted right now — see `useResolvedThemeMode`. */
  readonly resolvedMode: 'light' | 'dark';
  readonly onSelect: (name: CatppuccinSwatchName) => void;
};

// 48px hit target, 36px visible circle — docs/design-system.md §11.4.
const HIT_TARGET_CLASS = 'h-12 w-12';
const CIRCLE_CLASS = 'h-9 w-9';

/**
 * Catppuccin accent-colour picker. Modelled as a `radiogroup` of `radio`
 * cells — native ARIA roles on plain buttons, since the visual is a custom
 * circle rather than a native `<input type="radio">` — so a screen reader
 * announces this as a single-choice set (docs/design-system.md §11.4).
 *
 * Swatch fills come from `resolvedMode`, not the stored `themeMode`
 * directly, so the grid always shows the palette actually on screen,
 * including a live flip if `system` mode is tracking a live OS change.
 *
 * The check mark's colour is picked from `resolvedMode` rather than each
 * swatch's own luminance: every Latte hex is dark enough for a light check
 * and every Mocha hex is light enough for a dark check, so this is simpler
 * and more reliable than per-swatch contrast math.
 */
export function SwatchGrid({ selected, resolvedMode, onSelect }: SwatchGridProps): ReactElement {
  const palette = resolvedMode === 'light' ? CATPPUCCIN_LATTE : CATPPUCCIN_MOCHA;
  const checkClassName = resolvedMode === 'light' ? 'text-white' : 'text-black';

  return (
    <div role="radiogroup" aria-label="Accent colour" className="flex flex-wrap gap-1">
      {SWATCH_NAMES.map((name) => {
        const isSelected = name === selected;
        const label = SWATCH_LABELS[name];

        return (
          <button
            key={name}
            type="button"
            role="radio"
            aria-checked={isSelected}
            aria-label={`${label}, ${isSelected ? 'selected' : 'not selected'}`}
            onClick={() => onSelect(name)}
            className={`flex items-center justify-center rounded-full ${HIT_TARGET_CLASS}`}
          >
            <span
              className={`flex items-center justify-center rounded-full ${CIRCLE_CLASS}`}
              style={{ backgroundColor: palette[name] }}
            >
              {isSelected && <Icon name="check" className={checkClassName} size={20} />}
            </span>
          </button>
        );
      })}
    </div>
  );
}
