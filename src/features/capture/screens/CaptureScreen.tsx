import type { ReactElement } from 'react';
import { useNavigate } from 'react-router';

/**
 * Out-of-shell capture screen (`/capture`, sibling to `<App/>`, not a child
 * — see docs/architecture.md §5). Placeholder shell; the metadata header,
 * page preview, carousel, and tool row land in a later commit. See
 * docs/modules/capture.md.
 */
export function CaptureScreen(): ReactElement {
  const navigate = useNavigate();

  return (
    <div className="p-6">
      <button type="button" onClick={() => navigate(-1)} aria-label="Back">
        Back
      </button>
      <p>Capture screen — under construction.</p>
    </div>
  );
}
