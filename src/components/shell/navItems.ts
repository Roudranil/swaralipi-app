import type { MaterialSymbol } from 'material-symbols';

/** One entry in the shell's tab set, shared by `NavBar` and `NavRail`. */
export type NavItem = {
  readonly value: string;
  readonly label: string;
  readonly icon: MaterialSymbol;
};

export const NAV_ITEMS: ReadonlyArray<NavItem> = [
  { value: '/', label: 'Library', icon: 'library_music' },
  { value: '/settings', label: 'Settings', icon: 'settings' },
];

/**
 * Picks the nav item whose route owns `pathname`, so a nested route like
 * `/settings/appearance` still highlights the `/settings` tab. Falls back to
 * the root item when nothing else matches (there's always at least `/`).
 *
 * Sorts by descending value length first so a longer, more specific route
 * (e.g. `/settings`) wins over a shorter one that would otherwise also
 * prefix-match (e.g. `/`).
 */
export function activeNavValue(pathname: string): string {
  const sorted = [...NAV_ITEMS].sort((a, b) => b.value.length - a.value.length);
  const match = sorted.find(
    (item) => pathname === item.value || pathname.startsWith(`${item.value}/`),
  );
  return match?.value ?? '/';
}
