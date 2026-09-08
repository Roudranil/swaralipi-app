import 'mdui/components/button-icon.js';

import type { ReactElement, ReactNode } from 'react';

import { AppBar } from '../../../components/AppBar';
import { Icon } from '../../../components/Icon';

type SettingsPageProps = {
  readonly title: string;
  readonly children: ReactNode;
  /** Omit for the top-level settings list, which has no screen to return to. */
  readonly onBack?: () => void;
};

/**
 * Layout shell every settings screen renders through — this is the one
 * place the "uniform look across all settings screens" requirement is
 * enforced (docs/modules/settings.md §6).
 *
 * At laptop widths the nav rail already owns the left edge, so content is
 * capped at 640px and centred rather than opening a second nav column
 * (rejected two-pane list-detail layout — see docs/modules/settings.md §6).
 */
export function SettingsPage({ title, children, onBack }: SettingsPageProps): ReactElement {
  return (
    <>
      <AppBar>
        {onBack !== undefined && (
          <mdui-button-icon slot="navigation-icon" onClick={onBack} aria-label="Back">
            <Icon name="arrow_back" />
          </mdui-button-icon>
        )}
        <mdui-top-app-bar-title>{title}</mdui-top-app-bar-title>
      </AppBar>
      <div className="mx-auto w-full max-w-[640px] px-4 pb-24 md:px-6">{children}</div>
    </>
  );
}
