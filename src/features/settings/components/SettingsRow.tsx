import 'mdui/components/list-item.js';

import type { ReactElement } from 'react';
import type { MaterialSymbol } from 'material-symbols';
import { useNavigate } from 'react-router';

import { Icon } from '../../../components/Icon';

type SettingsRowProps = {
  readonly to: string;
  readonly icon: MaterialSymbol;
  readonly title: string;
  readonly description?: string;
  /** `status: 'planned'` registry entries render dim and inert. */
  readonly disabled?: boolean;
};

/**
 * One tappable settings entry row. Navigates via `useNavigate()` rather than
 * `href` — `href` on `mdui-list-item` renders an `<a>`, which would do a
 * full page load out of the SPA (see `src/components/AppBar.tsx` for the
 * same in-app-navigation concern applied to the app bar).
 *
 * Never uses `mdui-list-item`'s `icon`/`end-icon` attributes — those resolve
 * against the legacy `'Material Icons'` font we don't ship. `<Icon>` in the
 * `icon`/`end-icon` slots instead, per docs/design-system.md §12.
 */
export function SettingsRow({
  to,
  icon,
  title,
  description,
  disabled = false,
}: SettingsRowProps): ReactElement {
  const navigate = useNavigate();

  return (
    <mdui-list-item
      headline={title}
      description={description}
      disabled={disabled}
      rounded
      onClick={disabled ? undefined : () => navigate(to)}
    >
      <Icon slot="icon" name={icon} />
      <Icon slot="end-icon" name="chevron_right" />
    </mdui-list-item>
  );
}
