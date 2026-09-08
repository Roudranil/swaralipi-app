import type { ReactElement } from 'react';
import { useLocation, useNavigate } from 'react-router';

import { Icon } from '../Icon';
import { activeNavValue, NAV_ITEMS } from './navItems';

/**
 * Bottom navigation bar for phone widths (`< 840px`). Hidden above that via
 * `md:hidden` — see `NavRail` for the laptop-width equivalent.
 *
 * Hand-built with plain elements rather than `mdui-navigation-bar`/-item, so
 * the active row's geometry matches `NavRail`'s exactly. Each item paints
 * its own background directly when active — no shared/sliding indicator.
 */
export function NavBar(): ReactElement {
  const navigate = useNavigate();
  const location = useLocation();
  const activeValue = activeNavValue(location.pathname);

  return (
    <nav
      aria-label="Main navigation"
      // relative overrides mdui's usual :host{position:fixed} nav-bar
      // convention so this sits in its own grid row instead of overlaying
      // <main>; the safe-area padding closes the docs/design-system.md §9 gap.
      className="relative flex h-[calc(5rem+env(safe-area-inset-bottom))] items-center bg-[rgb(var(--mdui-color-surface-container))] pb-[env(safe-area-inset-bottom)] md:hidden"
    >
      {NAV_ITEMS.map((item) => {
        const active = item.value === activeValue;
        return (
          <button
            key={item.value}
            type="button"
            onClick={() => navigate(item.value)}
            aria-current={active ? 'page' : undefined}
            className="flex flex-1 flex-col items-center justify-center gap-1 text-xs"
          >
            <span
              className={`flex h-8 w-14 items-center justify-center rounded-full transition-colors ${
                active ? 'bg-[rgb(var(--mdui-color-secondary-container))]' : ''
              }`}
            >
              <Icon
                name={item.icon}
                filled={active}
                className={
                  active
                    ? 'text-[rgb(var(--mdui-color-on-secondary-container))]'
                    : 'text-[rgb(var(--mdui-color-on-surface-variant))]'
                }
              />
            </span>
            <span
              className={
                active
                  ? 'text-[rgb(var(--mdui-color-on-surface))]'
                  : 'text-[rgb(var(--mdui-color-on-surface-variant))]'
              }
            >
              {item.label}
            </span>
          </button>
        );
      })}
    </nav>
  );
}
