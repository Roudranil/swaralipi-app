/**
 * Declarative settings registry. This is the single source of truth for the
 * settings surface — routes, list rows, section dividers, and row summaries
 * are all derived from it (`settingsRoutes.ts`, `SettingsIndexScreen.tsx`).
 * Adding a setting is one entry here plus one screen file; nothing else
 * needs editing. See docs/modules/settings.md.
 */

import type { ComponentType } from 'react';
import type { MaterialSymbol } from 'material-symbols';

import { AboutScreen } from './screens/AboutScreen';
import { AppearanceScreen } from './screens/AppearanceScreen';
import { PersonalisationScreen } from './screens/PersonalisationScreen';
import { SWATCH_LABELS } from '../../lib/catppuccin';
import type { ThemeMode, UserPreferences } from '../../db/types';

export type SettingsEntryStatus = 'built' | 'planned';

/** One tappable row in a settings list, and the screen behind it. */
export type SettingsEntry = {
  readonly id: string;
  /** Path segment, relative to the parent entry (or to `/settings` at the top). */
  readonly path: string;
  readonly title: string;
  readonly icon: MaterialSymbol;
  readonly status: SettingsEntryStatus;
  /** Static secondary line. Ignored when `summary` is set. */
  readonly description?: string;
  /** Live secondary line, e.g. `"Dark, Mauve"`. Wins over `description`. */
  readonly summary?: (prefs: UserPreferences) => string;
  /** Leaf screen. Omit when `children` is set — a group screen is generated. */
  readonly Screen?: ComponentType;
  /** Nested subentries. Renders a generated group screen listing them. */
  readonly children?: ReadonlyArray<SettingsEntry>;
};

/** A divider-separated group of entries on the top-level settings list. */
export type SettingsSection = {
  readonly id: string;
  /** Omitted => divider only, no subheader (matches an unlabelled M3 group). */
  readonly label?: string;
  readonly entries: ReadonlyArray<SettingsEntry>;
};

const THEME_MODE_LABELS: Record<ThemeMode, string> = {
  light: 'Light',
  dark: 'Dark',
  system: 'System',
};

const appearanceSummary = (prefs: UserPreferences): string =>
  `${THEME_MODE_LABELS[prefs.themeMode]}, ${SWATCH_LABELS[prefs.seedColor]}`;

const personalisationSummary = (prefs: UserPreferences): string =>
  prefs.userName.trim() === '' ? 'Not set' : prefs.userName;

export const SETTINGS_SECTIONS: ReadonlyArray<SettingsSection> = [
  {
    id: 'personal',
    label: 'Personal',
    entries: [
      {
        id: 'personalisation',
        path: 'personalisation',
        title: 'Personalisation',
        icon: 'person',
        status: 'built',
        Screen: PersonalisationScreen,
        summary: personalisationSummary,
      },
      {
        id: 'appearance',
        path: 'appearance',
        title: 'Appearance',
        icon: 'palette',
        status: 'built',
        Screen: AppearanceScreen,
        summary: appearanceSummary,
      },
    ],
  },
  {
    id: 'library',
    label: 'Library',
    entries: [
      { id: 'tags', path: 'tags', title: 'Tags', icon: 'sell', status: 'planned' },
      { id: 'instruments', path: 'instruments', title: 'Instruments', icon: 'piano', status: 'planned' },
      {
        id: 'library',
        path: 'library',
        title: 'Library',
        icon: 'sort',
        status: 'planned',
        description: 'Default sort',
      },
      {
        id: 'customFields',
        path: 'custom-fields',
        title: 'Custom fields',
        icon: 'list_alt',
        status: 'planned',
      },
    ],
  },
  {
    id: 'maintenance',
    label: 'Housekeeping',
    entries: [{ id: 'trash', path: 'trash', title: 'Trash', icon: 'delete', status: 'planned' }],
  },
  {
    id: 'meta',
    label: 'Miscellaneous',
    entries: [
      { id: 'about', path: 'about', title: 'About', icon: 'info', status: 'built', Screen: AboutScreen },
      {
        id: 'licenses',
        path: 'licenses',
        title: 'Open source licences',
        icon: 'description',
        status: 'planned',
      },
      {
        id: 'backup',
        path: 'backup',
        title: 'Backup and sync',
        icon: 'cloud_sync',
        status: 'planned',
      },
    ],
  },
];
