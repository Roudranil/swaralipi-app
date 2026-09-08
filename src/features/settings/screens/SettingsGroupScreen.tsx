import type { ReactElement } from 'react';
import { useNavigate } from 'react-router';

import { SettingsPage } from '../components/SettingsPage';
import { SettingsRow } from '../components/SettingsRow';
import { SettingsSection } from '../components/SettingsSection';
import type { SettingsEntry } from '../registry';
import { usePreferences } from '../../../hooks/usePreferences';

type SettingsGroupScreenProps = {
  readonly entry: SettingsEntry;
};

/**
 * Generated screen for any registry entry that has `children` instead of a
 * `Screen` — lists its subentries exactly like the top-level settings list
 * does. This is what makes nesting free: a future `appearance > motion`
 * subentry needs only a new registry object, never a new screen file (see
 * docs/modules/settings.md §4).
 */
export function SettingsGroupScreen({ entry }: SettingsGroupScreenProps): ReactElement {
  const navigate = useNavigate();
  const preferences = usePreferences();
  const children = entry.children ?? [];

  return (
    <SettingsPage title={entry.title} onBack={() => navigate(-1)}>
      <SettingsSection first>
        {children.map((child) => (
          <SettingsRow
            key={child.id}
            to={child.path}
            icon={child.icon}
            title={child.title}
            description={child.summary ? child.summary(preferences) : child.description}
            disabled={child.status === 'planned'}
          />
        ))}
      </SettingsSection>
    </SettingsPage>
  );
}
