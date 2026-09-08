import 'mdui/components/button-icon.js';

import { useEffect, useRef, useState, type ReactElement, type ReactNode } from 'react';

import { Icon } from '../../../components/Icon';
import { decodeImage, renderToCanvas } from '../../../lib/render';
import type { RenderParams } from '../../../db/types';
import type { DraftPage } from '../draft';

/**
 * Runs `callback` after the browser has painted the *current* frame. A
 * single `requestAnimationFrame` fires just *before* that paint, so setting
 * a "jump" style and scheduling the "settle" style in one rAF collapses both
 * into the same commit with no visible motion — this waits for the second
 * rAF instead, which only fires after the first one's frame has painted.
 */
function afterNextPaint(callback: () => void): () => void {
  let inner = 0;
  const outer = requestAnimationFrame(() => {
    inner = requestAnimationFrame(callback);
  });
  return () => {
    cancelAnimationFrame(outer);
    cancelAnimationFrame(inner);
  };
}

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
  /**
   * A new `{ direction, token }` slides the canvas in from that side — `1`
   * (forward/next) slides in from the right, `-1` (back/previous) from the
   * left. Same one-shot-pulse shape as `rotationPulse`.
   */
  readonly stepPulse?: { readonly direction: -1 | 1; readonly token: number } | null;
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
  stepPulse,
}: PagePreviewProps): ReactElement {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const params = renderOverride ?? page?.renderParams;

  // spin-into-place: jump to `-delta` with its transition off, then
  // re-enable it and animate to `0` on the next frame. The canvas underneath
  // has already redrawn to its correct final orientation by the time this
  // starts, so the settle always lands on the right image. `rotate` and
  // `translate` (below) are independent CSS properties, not `transform`
  // components, so each can jump/animate on its own schedule without the
  // other's inline style clobbering it.
  const [spin, setSpin] = useState({ deg: 0, animate: false });
  const lastPulseToken = useRef<number | null>(null);

  useEffect(() => {
    if (!rotationPulse || rotationPulse.token === lastPulseToken.current) return;
    lastPulseToken.current = rotationPulse.token;
    setSpin({ deg: -rotationPulse.delta, animate: false });
    return afterNextPaint(() => setSpin({ deg: 0, animate: true }));
  }, [rotationPulse]);

  // slide-into-place: same pulse pattern as rotation, but for the prev/next
  // arrows — `direction: 1` (next) starts offset to the right and slides
  // left into place; `-1` (previous) starts offset left and slides right.
  const [slide, setSlide] = useState({ pct: 0, animate: false });
  const lastStepToken = useRef<number | null>(null);

  useEffect(() => {
    if (!stepPulse || stepPulse.token === lastStepToken.current) return;
    lastStepToken.current = stepPulse.token;
    setSlide({ pct: stepPulse.direction * 100, animate: false });
    return afterNextPaint(() => setSlide({ pct: 0, animate: true }));
  }, [stepPulse]);

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
    <div className="flex h-full w-full min-h-0 min-w-0 items-center justify-center gap-2 px-2">
      <mdui-button-icon aria-label="Previous page" disabled={!canStepBack} onClick={onStepBack}>
        <Icon name="chevron_left" />
      </mdui-button-icon>

      {/* the center of this box is the center of the space between the
          metadata header and the carousel/tool-action row, since this whole
          component fills its parent (`h-full w-full`) and centers within it. */}
      <div className="relative flex h-full min-h-0 max-w-full items-center justify-center">
        {page ? (
          <canvas
            ref={canvasRef}
            className="max-h-full max-w-full rounded-md object-contain"
            style={{
              rotate: `${spin.deg}deg`,
              translate: `${slide.pct}% 0`,
              transition: [
                `rotate ${spin.animate ? '300ms ease' : '0s'}`,
                `translate ${slide.animate ? '250ms ease' : '0s'}`,
              ].join(', '),
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
