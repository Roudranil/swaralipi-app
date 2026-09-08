import {
  argbFromHex,
  blueFromArgb,
  greenFromArgb,
  Hct,
  MaterialDynamicColors,
  redFromArgb,
  SchemeTonalSpot,
} from '@material/material-color-utilities';

/**
 * Generates the `--mdui-color-*` custom properties at the 2025 Expressive
 * color spec and writes them to `:root`, overriding MDUI's own 2021-spec
 * generator (`setColorScheme`). See docs/design-system.md §2.
 *
 * MDUI switches `-light`/`-dark` variants via the `mdui-theme-dark` class on
 * `<html>`, so we mirror that convention instead of calling MDUI's own
 * theming function.
 */

const COLOR_SPEC = '2025' as const;
const CONTRAST_LEVEL = 0;

const ROLE_GETTERS = {
  background: 'background',
  onBackground: 'onBackground',
  surface: 'surface',
  surfaceDim: 'surfaceDim',
  surfaceBright: 'surfaceBright',
  surfaceContainerLowest: 'surfaceContainerLowest',
  surfaceContainerLow: 'surfaceContainerLow',
  surfaceContainer: 'surfaceContainer',
  surfaceContainerHigh: 'surfaceContainerHigh',
  surfaceContainerHighest: 'surfaceContainerHighest',
  onSurface: 'onSurface',
  surfaceVariant: 'surfaceVariant',
  onSurfaceVariant: 'onSurfaceVariant',
  outline: 'outline',
  outlineVariant: 'outlineVariant',
  inverseSurface: 'inverseSurface',
  inverseOnSurface: 'inverseOnSurface',
  shadow: 'shadow',
  scrim: 'scrim',
  surfaceTint: 'surfaceTint',
  primary: 'primary',
  onPrimary: 'onPrimary',
  primaryContainer: 'primaryContainer',
  onPrimaryContainer: 'onPrimaryContainer',
  inversePrimary: 'inversePrimary',
  primaryFixed: 'primaryFixed',
  primaryFixedDim: 'primaryFixedDim',
  onPrimaryFixed: 'onPrimaryFixed',
  onPrimaryFixedVariant: 'onPrimaryFixedVariant',
  secondary: 'secondary',
  onSecondary: 'onSecondary',
  secondaryContainer: 'secondaryContainer',
  onSecondaryContainer: 'onSecondaryContainer',
  secondaryFixed: 'secondaryFixed',
  secondaryFixedDim: 'secondaryFixedDim',
  onSecondaryFixed: 'onSecondaryFixed',
  onSecondaryFixedVariant: 'onSecondaryFixedVariant',
  tertiary: 'tertiary',
  onTertiary: 'onTertiary',
  tertiaryContainer: 'tertiaryContainer',
  onTertiaryContainer: 'onTertiaryContainer',
  tertiaryFixed: 'tertiaryFixed',
  tertiaryFixedDim: 'tertiaryFixedDim',
  onTertiaryFixed: 'onTertiaryFixed',
  onTertiaryFixedVariant: 'onTertiaryFixedVariant',
  error: 'error',
  onError: 'onError',
  errorContainer: 'errorContainer',
  onErrorContainer: 'onErrorContainer',
} as const satisfies Record<string, keyof MaterialDynamicColors>;

const camelToKebab = (value: string): string =>
  value.replace(/[A-Z]/g, (letter) => `-${letter.toLowerCase()}`);

const rgbTriplet = (argb: number): string =>
  `${redFromArgb(argb)}, ${greenFromArgb(argb)}, ${blueFromArgb(argb)}`;

const buildSchemeVars = (
  scheme: SchemeTonalSpot,
  colors: MaterialDynamicColors,
  suffix: '' | '-light' | '-dark',
): string =>
  Object.entries(ROLE_GETTERS)
    .map(([role, getter]) => {
      const dynamicColor = colors[getter]();
      const argb = dynamicColor.getArgb(scheme);
      return `--mdui-color-${camelToKebab(role)}${suffix}: ${rgbTriplet(argb)};`;
    })
    .join('\n  ');

let styleElement: HTMLStyleElement | undefined;

/** Applies the M3 token layer for the given seed color to `document.documentElement`. */
export function applyTheme(seedHex: string): void {
  const colors = new MaterialDynamicColors();
  const sourceHct = Hct.fromInt(argbFromHex(seedHex));

  const lightScheme = new SchemeTonalSpot(
    sourceHct,
    false,
    CONTRAST_LEVEL,
    COLOR_SPEC,
  );
  const darkScheme = new SchemeTonalSpot(
    sourceHct,
    true,
    CONTRAST_LEVEL,
    COLOR_SPEC,
  );

  const lightVars = buildSchemeVars(lightScheme, colors, '-light');
  const darkVars = buildSchemeVars(darkScheme, colors, '-dark');
  const resolvedVars = Object.keys(ROLE_GETTERS)
    .map((role) => {
      const kebab = camelToKebab(role);
      return `--mdui-color-${kebab}: var(--mdui-color-${kebab}-light);`;
    })
    .join('\n  ');
  const darkResolvedVars = Object.keys(ROLE_GETTERS)
    .map((role) => {
      const kebab = camelToKebab(role);
      return `--mdui-color-${kebab}: var(--mdui-color-${kebab}-dark);`;
    })
    .join('\n  ');

  const cssText = `:root {
  ${lightVars}
  ${darkVars}
  ${resolvedVars}
}

.mdui-theme-dark {
  ${darkResolvedVars}
}

@media (prefers-color-scheme: dark) {
  .mdui-theme-auto {
    ${darkResolvedVars}
  }
}`;

  if (!styleElement) {
    styleElement = document.createElement('style');
    styleElement.id = 'swaralipi-theme-tokens';
    document.head.append(styleElement);
  }
  styleElement.textContent = cssText;
}
