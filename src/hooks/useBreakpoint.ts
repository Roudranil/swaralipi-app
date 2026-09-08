import { useEffect, useState } from 'react';

export type NavLayout = 'bar' | 'rail' | 'drawer';

const RAIL_QUERY = '(min-width: 840px)';
const DRAWER_QUERY = '(min-width: 1080px)';

const layoutFromMedia = (isRail: boolean, isDrawer: boolean): NavLayout => {
  if (isDrawer) return 'drawer';
  if (isRail) return 'rail';
  return 'bar';
};

/** Adaptive navigation layout per the M3 breakpoints in docs/architecture.md §5.2. */
export function useBreakpoint(): NavLayout {
  const [layout, setLayout] = useState<NavLayout>(() => {
    if (typeof window === 'undefined') return 'bar';
    return layoutFromMedia(
      window.matchMedia(RAIL_QUERY).matches,
      window.matchMedia(DRAWER_QUERY).matches,
    );
  });

  useEffect(() => {
    const railQuery = window.matchMedia(RAIL_QUERY);
    const drawerQuery = window.matchMedia(DRAWER_QUERY);

    const update = (): void => {
      setLayout(layoutFromMedia(railQuery.matches, drawerQuery.matches));
    };

    railQuery.addEventListener('change', update);
    drawerQuery.addEventListener('change', update);
    return () => {
      railQuery.removeEventListener('change', update);
      drawerQuery.removeEventListener('change', update);
    };
  }, []);

  return layout;
}
