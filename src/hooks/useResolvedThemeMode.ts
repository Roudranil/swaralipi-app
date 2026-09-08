import { useEffect, useState } from 'react';

import type { ThemeMode } from '../db/types';

const DARK_QUERY = '(prefers-color-scheme: dark)';

/**
 * Resolves `'system'` mode to the OS's live preference, so UI that needs to
 * know which palette is actually painted (the appearance swatch grid) isn't
 * forced to duplicate `applyThemeMode()`'s logic. Updates live if the OS
 * preference flips while `system` is active.
 */
export function useResolvedThemeMode(mode: ThemeMode): 'light' | 'dark' {
  const [systemPrefersDark, setSystemPrefersDark] = useState(
    () => window.matchMedia(DARK_QUERY).matches,
  );

  useEffect(() => {
    const query = window.matchMedia(DARK_QUERY);
    const listener = (event: MediaQueryListEvent): void => setSystemPrefersDark(event.matches);
    query.addEventListener('change', listener);
    return () => query.removeEventListener('change', listener);
  }, []);

  if (mode === 'system') return systemPrefersDark ? 'dark' : 'light';
  return mode;
}
