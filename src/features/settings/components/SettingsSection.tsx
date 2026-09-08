import 'mdui/components/divider.js';
import 'mdui/components/list.js';
import 'mdui/components/list-subheader.js';

import type { ReactElement, ReactNode } from 'react';

type SettingsSectionProps = {
  /** Omitted => divider only, no subheader — an unlabelled M3 group. */
  readonly label?: string;
  readonly children: ReactNode;
  /** Suppresses the leading divider — the first section on a screen has no rule above it. */
  readonly first?: boolean;
};

/**
 * One divider-separated group of `SettingsRow`s, with an optional subheader.
 * The single place section rhythm is defined, so every settings screen's
 * grouping reads identically — see docs/modules/settings.md §6.
 */
export function SettingsSection({
  label,
  children,
  first = false,
}: SettingsSectionProps): ReactElement {
  return (
    <>
      {!first && <mdui-divider />}
      <mdui-list>
        {label !== undefined && (
          <mdui-list-subheader className="text-[rgb(var(--mdui-color-on-surface-variant))]">
            {label}
          </mdui-list-subheader>
        )}
        {children}
      </mdui-list>
    </>
  );
}
