import 'mdui/components/segmented-button-group.js';
import 'mdui/components/segmented-button.js';
import 'mdui/components/button.js';
import 'mdui/components/dialog.js';

import { useEffect, useRef, useState, type ReactElement } from 'react';
import { useNavigate } from 'react-router';

import { SettingsGroup } from '../components/SettingsGroup';
import { SettingsPage } from '../components/SettingsPage';
import { SwatchGrid } from '../components/SwatchGrid';
import { DEFAULT_SEED_SWATCH, type CatppuccinSwatchName } from '../../../lib/catppuccin';
import { logError } from '../../../lib/log';
import { isThemeMode } from '../../../lib/themeBoot';
import { updatePreferences } from '../../../db/repositories/preferences';
import { Icon } from '../../../components/Icon';
import { useCustomEvent } from '../../../hooks/useCustomEvent';
import { usePreferences } from '../../../hooks/usePreferences';
import { useResolvedThemeMode } from '../../../hooks/useResolvedThemeMode';

/**
 * Theme mode + accent colour. Both write straight to `preferences` —
 * `useAppliedTheme()` (mounted once in `App.tsx`) re-themes the app as soon
 * as the write lands, so there is no local mode/colour state to keep in
 * sync here (docs/modules/settings.md §8).
 */
export function AppearanceScreen(): ReactElement {
  const navigate = useNavigate();
  const preferences = usePreferences();
  const resolvedMode = useResolvedThemeMode(preferences.themeMode);

  const themeGroupRef = useRef<HTMLElement & { value: string }>(null);
  const resetDialogRef = useRef<HTMLElement>(null);
  const [resetOpen, setResetOpen] = useState(false);

  // The `value` attribute only seeds the segmented button group's *initial*
  // selection (mdui docs) — react to external changes (e.g. Reset) by
  // setting the live JS property directly, same as any other controlled
  // custom element in this codebase.
  useEffect(() => {
    if (themeGroupRef.current) themeGroupRef.current.value = preferences.themeMode;
  }, [preferences.themeMode]);

  useCustomEvent(themeGroupRef, 'change', () => {
    const value = themeGroupRef.current?.value;
    if (!isThemeMode(value)) return;
    updatePreferences({ themeMode: value }).catch((error: unknown) => {
      logError('failed to save theme mode', error);
    });
  });

  // Syncs back if the user dismisses via ESC or an overlay click rather
  // than the Cancel/Reset buttons, which only set `open` on the JS side.
  useCustomEvent(resetDialogRef, 'closed', () => setResetOpen(false));

  const handleSelectSwatch = (name: CatppuccinSwatchName): void => {
    updatePreferences({ seedColor: name }).catch((error: unknown) => {
      logError('failed to save accent colour', error);
    });
  };

  const handleReset = (): void => {
    setResetOpen(false);
    updatePreferences({ themeMode: 'system', seedColor: DEFAULT_SEED_SWATCH }).catch(
      (error: unknown) => {
        logError('failed to reset appearance', error);
      },
    );
  };

  return (
    <SettingsPage title="Appearance" onBack={() => navigate(-1)}>
      <SettingsGroup label="Theme">
        <mdui-segmented-button-group
          ref={themeGroupRef}
          selects="single"
          required
          value={preferences.themeMode}
          full-width
        >
          <mdui-segmented-button value="light">
            <Icon slot="icon" name="light_mode" />
            Light
          </mdui-segmented-button>
          <mdui-segmented-button value="dark">
            <Icon slot="icon" name="dark_mode" />
            Dark
          </mdui-segmented-button>
          <mdui-segmented-button value="system">
            <Icon slot="icon" name="contrast" />
            System
          </mdui-segmented-button>
        </mdui-segmented-button-group>
      </SettingsGroup>

      <SettingsGroup label="Accent colour">
        <SwatchGrid
          selected={preferences.seedColor}
          resolvedMode={resolvedMode}
          onSelect={handleSelectSwatch}
        />
      </SettingsGroup>

      <mdui-button variant="text" onClick={() => setResetOpen(true)}>
        Reset appearance
      </mdui-button>

      <mdui-dialog
        ref={resetDialogRef}
        headline="Reset appearance?"
        open={resetOpen}
        close-on-esc
        close-on-overlay-click
      >
        <mdui-button slot="action" variant="text" onClick={() => setResetOpen(false)}>
          Cancel
        </mdui-button>
        <mdui-button slot="action" variant="text" onClick={handleReset}>
          Reset
        </mdui-button>
      </mdui-dialog>
    </SettingsPage>
  );
}
