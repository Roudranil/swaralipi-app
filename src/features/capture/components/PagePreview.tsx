import 'mdui/components/button-icon.js';

import { useEffect, useRef, type ReactElement, type ReactNode } from 'react';

import { Icon } from '../../../components/Icon';
import { decodeImage, renderToCanvas } from '../../../lib/render';
import type { DraftPage } from '../draft';

type PagePreviewProps = {
  readonly page: DraftPage | undefined;
  readonly canStepBack: boolean;
  readonly canStepForward: boolean;
  readonly onStepBack: () => void;
  readonly onStepForward: () => void;
  /** Overlaid on top of the canvas, e.g. `CropOverlay` in crop mode. */
  readonly overlay?: ReactNode;
};

/**
 * Large single-page preview with prev/next arrows. Renders `page` through
 * the full `RenderParams` pipeline (`src/lib/render.ts`) on every change, so
 * what's shown always matches what Save would persist — see
 * docs/modules/capture.md §2.
 */
export function PagePreview({
  page,
  canStepBack,
  canStepForward,
  onStepBack,
  onStepForward,
  overlay,
}: PagePreviewProps): ReactElement {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    if (!page) return;
    let cancelled = false;

    decodeImage(page.blob)
      .then((bitmap) => {
        if (cancelled) return;
        const rendered = renderToCanvas(bitmap, page.renderParams);
        bitmap.close();
        const canvas = canvasRef.current;
        if (!canvas) return;
        canvas.width = rendered.width;
        canvas.height = rendered.height;
        canvas.getContext('2d')?.drawImage(rendered, 0, 0);
      })
      .catch(() => {
        // decode failures surface as a blank preview; the page itself isn't lost.
      });

    return () => {
      cancelled = true;
    };
  }, [page]);

  return (
    <div className="relative flex items-center justify-center gap-2 px-2 py-4">
      <mdui-button-icon aria-label="Previous page" disabled={!canStepBack} onClick={onStepBack}>
        <Icon name="chevron_left" />
      </mdui-button-icon>

      <div className="relative max-h-[60vh] max-w-full">
        {page ? (
          <canvas ref={canvasRef} className="max-h-[60vh] max-w-full rounded-md object-contain" />
        ) : (
          <p className="text-[rgb(var(--mdui-color-on-surface-variant))]">No pages yet</p>
        )}
        {overlay}
      </div>

      <mdui-button-icon aria-label="Next page" disabled={!canStepForward} onClick={onStepForward}>
        <Icon name="chevron_right" />
      </mdui-button-icon>
    </div>
  );
}
