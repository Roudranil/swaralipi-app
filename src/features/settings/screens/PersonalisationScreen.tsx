import 'mdui/components/button.js';
import 'mdui/components/snackbar.js';
import 'mdui/components/text-field.js';

import { useEffect, useRef, useState, type ReactElement } from 'react';
import { useNavigate } from 'react-router';

import { SettingsGroup } from '../components/SettingsGroup';
import { SettingsPage } from '../components/SettingsPage';
import { MAX_NAME_LENGTH, titleCaseName, validateName } from '../nameField';
import { updatePreferences } from '../../../db/repositories/preferences';
import { greeting } from '../../../lib/greeting';
import { logError } from '../../../lib/log';
import { useCustomEvent } from '../../../hooks/useCustomEvent';
import { usePreferences } from '../../../hooks/usePreferences';

/**
 * "Your name" feeds the Library greeting (`src/lib/greeting.ts`). Commits
 * via an explicit Save, unlike Appearance's instant-apply controls — a name
 * is free text that needs validation before it's worth persisting (see
 * docs/modules/settings.md §9).
 */
export function PersonalisationScreen(): ReactElement {
  const navigate = useNavigate();
  const preferences = usePreferences();
  const [draft, setDraft] = useState(preferences.userName);
  const [saved, setSaved] = useState(false);
  const inputRef = useRef<HTMLElement & { value: string }>(null);
  const snackbarRef = useRef<HTMLElement>(null);

  // `usePreferences()` returns `DEFAULT_PREFERENCES` (empty name) on the
  // first render, before Dexie resolves — `draft`'s initial state was
  // already captured by then. This effect is the one legitimate case for
  // `set-state-in-effect`: it synchronizes `draft` with an external system
  // (Dexie resolving) rather than deriving from a prop, so it can't be
  // done during render.
  useEffect(() => {
    // oxlint-disable-next-line react/set-state-in-effect
    setDraft(preferences.userName);
    if (inputRef.current) inputRef.current.value = preferences.userName;
  }, [preferences.userName]);

  // `input` is a CustomEvent on mdui-text-field — React's onChange/onInput
  // props typecheck but never fire (docs/design-system.md §10 rule 1).
  useCustomEvent(inputRef, 'input', () => {
    setDraft(inputRef.current?.value ?? '');
  });
  useCustomEvent(snackbarRef, 'closed', () => setSaved(false));

  const validation = validateName(draft);
  const canonical = titleCaseName(draft);
  const unchanged = canonical === preferences.userName;
  const canSave = validation.valid && !unchanged;

  // Title-cases on blur, not per keystroke, so the rewrite doesn't fight
  // the caret mid-word. Writes the field's own value imperatively since
  // it isn't otherwise controlled (see `inputRef` above).
  const handleBlur = (): void => {
    setDraft(canonical);
    if (inputRef.current) inputRef.current.value = canonical;
  };

  const handleSave = (): void => {
    if (!canSave) return;
    updatePreferences({ userName: canonical })
      .then(() => setSaved(true))
      .catch((error: unknown) => {
        logError('failed to save name', error);
      });
  };

  return (
    <SettingsPage title="Personalisation" onBack={() => navigate(-1)}>
      <SettingsGroup label="Your name">
        <mdui-text-field
          ref={inputRef}
          label="Your name"
          value={preferences.userName}
          maxlength={MAX_NAME_LENGTH}
          helper={
            validation.valid
              ? 'One word, letters only. Leave empty for a plain "Hi".'
              : validation.error
          }
          onBlur={handleBlur}
        />

        <div className="mt-4 rounded-md bg-[rgb(var(--mdui-color-surface-container-high))] px-4 py-3 text-[rgb(var(--mdui-color-on-surface))]">
          {greeting(draft)}
        </div>

        <mdui-button variant="filled" disabled={!canSave} onClick={handleSave} className="mt-4">
          Save
        </mdui-button>
      </SettingsGroup>

      <mdui-snackbar ref={snackbarRef} open={saved}>
        Saved
      </mdui-snackbar>
    </SettingsPage>
  );
}
