import type { RouteObject } from 'react-router';

import { SETTINGS_SECTIONS, type SettingsEntry } from './registry';
import { SettingsGroupScreen } from './screens/SettingsGroupScreen';

const isDefined = <T,>(value: T | undefined): value is T => value !== undefined;

/**
 * Turns one registry entry into a route, recursively. `status: 'planned'`
 * entries yield no route at all, so a disabled row can never be reached by
 * URL even if the user hand-types it — the registry is the only gate.
 */
function buildRoute(entry: SettingsEntry): RouteObject | undefined {
  if (entry.status === 'planned') return undefined;

  if (entry.children) {
    const childRoutes = entry.children.map(buildRoute).filter(isDefined);
    return {
      path: entry.path,
      children: [
        { index: true, element: <SettingsGroupScreen entry={entry} /> },
        ...childRoutes,
      ],
    };
  }

  if (!entry.Screen) return undefined;
  const Screen = entry.Screen;
  return { path: entry.path, element: <Screen /> };
}

/** Flattens `SETTINGS_SECTIONS` into the `react-router` children of `/settings`. */
export function settingsRoutes(): RouteObject[] {
  return SETTINGS_SECTIONS.flatMap((section) => section.entries.map(buildRoute)).filter(isDefined);
}
