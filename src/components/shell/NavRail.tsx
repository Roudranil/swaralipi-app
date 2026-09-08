import type { ReactElement } from 'react';
import type { MaterialSymbol } from 'material-symbols';
import { useLocation, useNavigate } from 'react-router';

import { Icon } from '../Icon';
import { activeNavValue, NAV_ITEMS } from './navItems';

type NavRailProps = {
  readonly expanded: boolean;
  readonly onToggle: () => void;
};

// shared by the toggle row and every nav item row so nothing shifts position
// or changes height when the rail expands/collapses.
const ROW_HEIGHT = 'h-14';
const ICON_COLUMN_WIDTH = 'w-24';
const LABEL_WIDTH = 'w-28';
// slow enough to read as a deliberate expand/collapse, not a flicker.
const WIDTH_TRANSITION = 'transition-all duration-500 ease-spring';

type RailRowProps = {
  readonly icon: MaterialSymbol;
  readonly label: string;
  readonly expanded: boolean;
  readonly active?: boolean;
  readonly ariaLabel?: string;
  readonly onClick: () => void;
};

/**
 * One row of the rail: a fixed-width icon column (never moves, never
 * resizes) plus a label that animates open/closed. Used for both the
 * expand/collapse toggle and the nav items so all rows share one geometry.
 */
function RailRow({ icon, label, expanded, active = false, ariaLabel, onClick }: RailRowProps): ReactElement {
  return (
    <button
      type="button"
      onClick={onClick}
      aria-label={ariaLabel}
      aria-current={active ? 'page' : undefined}
      className={`flex ${ROW_HEIGHT} w-full items-center rounded-full transition-colors ${
        active
          ? 'bg-[rgb(var(--mdui-color-secondary-container))] text-[rgb(var(--mdui-color-on-secondary-container))]'
          : 'text-[rgb(var(--mdui-color-on-surface-variant))] hover:bg-[rgb(var(--mdui-color-on-surface)/8%)]'
      }`}
    >
      <span className={`flex ${ICON_COLUMN_WIDTH} shrink-0 items-center justify-center`}>
        <Icon name={icon} filled={active} />
      </span>
      <span
        className={`overflow-hidden whitespace-nowrap text-left ${WIDTH_TRANSITION} ${
          expanded ? `${LABEL_WIDTH} opacity-100` : 'w-0 opacity-0'
        }`}
      >
        {label}
      </span>
    </button>
  );
}

/**
 * Laptop-width navigation (`>= 840px`, `md:` in Tailwind). Toggles between a
 * 96px collapsed rail and a wider expanded rail — mdui ships no expanded
 * rail (M3 Expressive deprecated the standard navigation drawer in its
 * favor), so this is hand-built with plain elements rather than switching
 * between two different mdui component trees. Swapping component trees on
 * toggle was tried first and rejected: mdui-button-icon and
 * mdui-navigation-rail-item center content differently, so the toggle button
 * visibly jumped position and rows changed height between states.
 *
 * The active row paints its own background directly (no shared/sliding
 * indicator) — a cross-item sliding pill was tried and dropped: it required
 * measuring DOM rects that went stale across the rail's own width
 * transition, and wasn't worth the complexity.
 */
export function NavRail({ expanded, onToggle }: NavRailProps): ReactElement {
  const navigate = useNavigate();
  const location = useLocation();
  const activeValue = activeNavValue(location.pathname);

  return (
    <nav
      aria-label="Main navigation"
      className={`relative hidden h-full flex-col overflow-hidden bg-[rgb(var(--mdui-color-surface-container))] md:flex ${WIDTH_TRANSITION} ${
        expanded ? 'w-56' : ICON_COLUMN_WIDTH
      }`}
    >
      <RailRow
        icon={expanded ? 'menu_open' : 'menu'}
        label=""
        expanded={expanded}
        ariaLabel={expanded ? 'Collapse navigation' : 'Expand navigation'}
        onClick={onToggle}
      />
      <div className="flex flex-col gap-1">
        {NAV_ITEMS.map((item) => (
          <RailRow
            key={item.value}
            icon={item.icon}
            label={item.label}
            expanded={expanded}
            active={item.value === activeValue}
            onClick={() => navigate(item.value)}
          />
        ))}
      </div>
    </nav>
  );
}
