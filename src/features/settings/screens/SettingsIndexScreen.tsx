import type { ReactElement } from 'react';

import { SettingsPage } from '../components/SettingsPage';
import { SettingsRow } from '../components/SettingsRow';
import { SettingsSection } from '../components/SettingsSection';
import { SETTINGS_SECTIONS } from '../registry';
import { usePreferences } from '../../../hooks/usePreferences';

/** The top-level `/settings` list — every row and divider comes from `SETTINGS_SECTIONS`. */
export function SettingsIndexScreen(): ReactElement {
  const preferences = usePreferences();

  return (
    <SettingsPage title="Settings">
      {SETTINGS_SECTIONS.map((section, index) => (
        <SettingsSection key={section.id} label={section.label} first={index === 0}>
          {section.entries.map((entry) => (
            <SettingsRow
              key={entry.id}
              to={entry.path}
              icon={entry.icon}
              title={entry.title}
              description={entry.summary ? entry.summary(preferences) : entry.description}
              disabled={entry.status === 'planned'}
            />
          ))}
        </SettingsSection>
      ))}
    </SettingsPage>
  );
}
