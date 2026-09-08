import type { CSSProperties, ReactElement } from 'react';
import type { MaterialSymbol } from 'material-symbols';

/** Icon silhouette family. Rounded matches the M3 Expressive direction (docs/design-system.md). */
export type IconVariant = 'outlined' | 'rounded' | 'sharp';

/** Valid values for the `wght` variable-font axis. */
export type IconWeight = 100 | 200 | 300 | 400 | 500 | 600 | 700;

// optical size (`opsz`) axis bounds from the material-symbols variable font spec.
const OPSZ_MIN = 20;
const OPSZ_MAX = 48;
const DEFAULT_VARIANT: IconVariant = 'rounded';
const DEFAULT_WEIGHT: IconWeight = 400;
const DEFAULT_GRADE = 0;

type IconProps = {
  /** Material Symbol name, e.g. `"library_music"`. Typo-checked against the full symbol set. */
  readonly name: MaterialSymbol;
  /** Silhouette family. Defaults to `"rounded"`. */
  readonly variant?: IconVariant;
  /** `FILL` axis: outline (`false`, default) or filled (`true`). */
  readonly filled?: boolean;
  /** `wght` axis. Defaults to `400`. */
  readonly weight?: IconWeight;
  /** `GRAD` axis, -25 to 200. Defaults to `0`. */
  readonly grade?: number;
  /**
   * Pixel size. Also drives the `opsz` axis, clamped to the font's
   * supported range. Omit to inherit `font-size` from the parent — this is
   * required inside MDUI icon slots, whose own styles set the size
   * (`::slotted([slot=icon]){font-size:inherit}` for nav items,
   * `1.5rem` for list items — see docs/design-system.md).
   */
  readonly size?: number;
  readonly className?: string;
  /** Forwarded so the icon can fill an MDUI slot, e.g. `slot="icon"`. */
  readonly slot?: string;
  /**
   * Accessible label. Omit for purely decorative icons (the default) —
   * without one the icon is `aria-hidden`, since its text content is the
   * raw symbol name and would otherwise be read aloud by a screen reader.
   */
  readonly label?: string;
};

/**
 * Renders a single Material Symbol glyph.
 *
 * The only sanctioned way to render an icon in this app — never use MDUI's
 * `icon=`/`active-icon=` attributes, which resolve against the legacy
 * `'Material Icons'` font family and cannot be re-pointed from outside their
 * shadow root (docs/design-system.md). Drop this into MDUI's `icon` /
 * `active-icon` slots instead via the `slot` prop.
 *
 * Color is intentionally not a prop: the glyph always renders in
 * `currentColor`, so color comes from a Tailwind class or MDUI color token
 * on an ancestor, per docs/design-system.md §3.
 */
export function Icon({
  name,
  variant = DEFAULT_VARIANT,
  filled = false,
  weight = DEFAULT_WEIGHT,
  grade = DEFAULT_GRADE,
  size,
  className,
  slot,
  label,
}: IconProps): ReactElement {
  const opsz = size === undefined ? OPSZ_MAX : Math.min(OPSZ_MAX, Math.max(OPSZ_MIN, size));

  const style: CSSProperties = {
    fontVariationSettings: `'FILL' ${filled ? 1 : 0}, 'wght' ${weight}, 'GRAD' ${grade}, 'opsz' ${opsz}`,
    ...(size === undefined ? {} : { fontSize: `${size}px` }),
  };

  return (
    <span
      className={`material-symbols-${variant}${className ? ` ${className}` : ''}`}
      style={style}
      slot={slot}
      aria-label={label}
      aria-hidden={label === undefined ? 'true' : undefined}
    >
      {name}
    </span>
  );
}
