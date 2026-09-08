import 'mdui/components/fab.js';

import type { ReactElement } from 'react';
import type { MaterialSymbol } from 'material-symbols';

import { Icon } from './Icon';

type FabProps = {
  readonly icon: MaterialSymbol;
  readonly label: string;
  readonly extended: boolean;
  readonly onClick: () => void;
  readonly className?: string;
};

/**
 * Shared FAB. `extended` collapses to an icon-only circle or expands to
 * icon+label using mdui's own transition (docs/design-system.md §8.2's
 * ~250ms spring) — no hand-rolled morph. Never the `icon=` attribute
 * (docs/design-system.md §12); the icon goes in the `icon` slot.
 *
 * Two call sites mount this with different `extended` sources — `LibraryScreen`
 * on phone (always extended) and `NavRail` on laptop (tied to the rail's own
 * expanded state) — because the FAB's placement genuinely differs by tier.
 * See docs/modules/capture.md §3.
 */
export function Fab({ icon, label, extended, onClick, className }: FabProps): ReactElement {
  return (
    <mdui-fab variant="primary" extended={extended} onClick={onClick} className={className}>
      <Icon slot="icon" name={icon} />
      {label}
    </mdui-fab>
  );
}
