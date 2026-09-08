import type { ReactElement, ReactNode } from 'react';

type SettingsGroupProps = {
  readonly label: string;
  readonly children: ReactNode;
};

/**
 * Labelled group of controls inside a settings screen — unlike
 * `SettingsSection`, this isn't a list of navigable rows, so it renders as
 * plain layout rather than an `mdui-list`. Used by `AppearanceScreen` for
 * "Theme" and "Accent colour" (docs/design-system.md §5 "Settings row
 * title"-adjacent label style).
 */
export function SettingsGroup({ label, children }: SettingsGroupProps): ReactElement {
  return (
    <section className="py-4">
      <h2 className="px-1 pb-3 text-sm font-medium tracking-wide text-[rgb(var(--mdui-color-on-surface-variant))]">
        {label}
      </h2>
      {children}
    </section>
  );
}
