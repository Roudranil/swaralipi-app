import 'mdui/components/button-icon.js';

import { useEffect, useRef, useState, type ReactElement, type ReactNode } from 'react';

import { Icon } from '../../../components/Icon';
import { decodeImage, renderToCanvas } from '../../../lib/render';
import type { RenderParams } from '../../../db/types';
import type { DraftPage } from '../draft';

type PagePreviewProps = {
  readonly page: DraftPage | undefined;
  readonly canStepBack: boolean;
  readonly canStepForward: boolean;
  readonly onStepBack: () => void;
  readonly onStepForward: () => void;
  /**
   * Overrides `page.renderParams` for display only — used in crop mode to
   * show the un-cropped, rotated image while the stored crop rect is
   * unaffected until the user actually drags the box.
   */
  readonly renderOverride?: RenderParams;
  /** Overlaid on top of the canvas, e.g. `CropOverlay` in crop mode. */
  readonly overlay?: ReactNode;
  /**
   * A new `{ delta, token }` (any `token` change, even with the same
   * `delta`) spins the canvas from `-delta` back to `0` — the redraw itself
   * is instant, so this is what makes rotation feel animated rather than a
   * hard cut. See docs/modules/capture.md §5.
   */
  readonly rotationPulse?: { readonly delta: -90 | 90; readonly token: number } | null;
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
  renderOverride,
  overlay,
  rotationPulse,
}: PagePreviewProps): ReactElement {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const params = renderOverride ?? page?.renderParams;

  // spin-into-place: jump to `-delta` with transitions off, then re-enable
  // them and animate to `0` on the next frame. The canvas underneath has
  // already redrawn to its correct final orientation by the time this
  // starts, so the settle always lands on the right image.
  const [spin, setSpin] = useState({ deg: 0, animate: false });
  const lastPulseToken = useRef<number | null>(null);

  useEffect(() => {
    if (!rotationPulse || rotationPulse.token === lastPulseToken.current) return;
    lastPulseToken.current = rotationPulse.token;
    setSpin({ deg: -rotationPulse.delta, animate: false });
    const frame = requestAnimationFrame(() => setSpin({ deg: 0, animate: true }));
    return () => cancelAnimationFrame(frame);
  }, [rotationPulse]);

  useEffect(() => {
    if (!page || !params) return;
    let cancelled = false;

    decodeImage(page.blob)
      .then((bitmap) => {
        if (cancelled) return;
        const rendered = renderToCanvas(bitmap, params);
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
  }, [page, params]);

  return (
    <div className="relative flex items-center justify-center gap-2 px-2 py-4">
      <mdui-button-icon aria-label="Previous page" disabled={!canStepBack} onClick={onStepBack}>
        <Icon name="chevron_left" />
      </mdui-button-icon>

      <div className="relative max-h-[60vh] max-w-full">
        {page ? (
          <canvas
            ref={canvasRef}
            className="max-h-[60vh] max-w-full rounded-md object-contain"
            style={{
              transform: `rotate(${spin.deg}deg)`,
              transition: spin.animate ? 'transform 300ms ease' : 'none',
            }}
          />
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
