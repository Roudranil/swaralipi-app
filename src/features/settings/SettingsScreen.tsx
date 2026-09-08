import type { ReactElement } from 'react';

import { AppBar } from '../../components/AppBar';

/** Placeholder — settings fields (appearance, custom fields, etc.) are not built yet. */
export function SettingsScreen(): ReactElement {
  return (
    <>
      <AppBar>
        <mdui-top-app-bar-title>Settings</mdui-top-app-bar-title>
      </AppBar>
      <div className="p-6 text-[rgb(var(--mdui-color-on-surface-variant))]">
        Settings — not built yet
      </div>
    </>
  );
}
