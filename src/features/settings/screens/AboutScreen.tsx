import { useEffect, useState, type ReactElement } from 'react';
import { useNavigate } from 'react-router';

import { SettingsPage } from '../components/SettingsPage';
import { logError } from '../../../lib/log';

const BYTES_PER_MEBIBYTE = 1024 * 1024;

/** Formats a byte count as whole MiB — the only precision this screen needs. */
const formatMebibytes = (bytes: number): string => `${Math.round(bytes / BYTES_PER_MEBIBYTE)} MiB`;

/** App identity and on-device storage usage. Everything else here is `planned`. */
export function AboutScreen(): ReactElement {
  const navigate = useNavigate();
  const [usage, setUsage] = useState<string | undefined>(undefined);

  useEffect(() => {
    navigator.storage
      .estimate()
      .then((estimate) => {
        if (estimate.usage !== undefined) setUsage(formatMebibytes(estimate.usage));
      })
      .catch((error: unknown) => {
        logError('failed to read storage estimate', error);
      });
  }, []);

  return (
    <SettingsPage title="About" onBack={() => navigate(-1)}>
      <div className="flex flex-col gap-1 py-4">
        <p className="text-[rgb(var(--mdui-color-on-surface))]">Swaralipi</p>
        <p className="text-sm text-[rgb(var(--mdui-color-on-surface-variant))]">
          Digitize and navigate hand-written sargam notations.
        </p>
        <p className="mt-4 text-sm text-[rgb(var(--mdui-color-on-surface-variant))]">
          On-device storage used: {usage ?? 'Calculating…'}
        </p>
      </div>
    </SettingsPage>
  );
}
