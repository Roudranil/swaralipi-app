import { useRef, type PointerEvent as ReactPointerEvent, type ReactElement } from 'react';

import type { CropRect } from '../../../db/types';

type Handle = 'move' | 'nw' | 'n' | 'ne' | 'e' | 'se' | 's' | 'sw' | 'w';

/** Smallest crop box, as a fraction of the preview, so it can't collapse to nothing. */
const MIN_CROP_FRACTION = 0.05;

type CropOverlayProps = {
  /** Normalized 0-1 rect, already in the *displayed* (rotated) image's space. */
  readonly rect: CropRect;
  readonly onChange: (rect: CropRect) => void;
};

function clamp01(value: number): number {
  return Math.min(1, Math.max(0, value));
}

/**
 * Crop bounding box: 4 corner handles, 4 edge handles, and whole-box drag.
 * v1 is rectangle-only with a free aspect ratio (no shape/lock support yet).
 * Uses Pointer Events with `setPointerCapture` for one code path across
 * touch, mouse, and stylus. See docs/modules/capture.md §4.
 */
export function CropOverlay({ rect, onChange }: CropOverlayProps): ReactElement {
  const containerRef = useRef<HTMLDivElement>(null);
  const dragRef = useRef<{ handle: Handle; startRect: CropRect; startX: number; startY: number } | null>(null);

  const beginDrag = (handle: Handle) => (event: ReactPointerEvent<HTMLDivElement>): void => {
    event.currentTarget.setPointerCapture(event.pointerId);
    dragRef.current = { handle, startRect: rect, startX: event.clientX, startY: event.clientY };
  };

  const handlePointerMove = (event: ReactPointerEvent<HTMLDivElement>): void => {
    const drag = dragRef.current;
    const container = containerRef.current;
    if (!drag || !container) return;

    const bounds = container.getBoundingClientRect();
    const dx = (event.clientX - drag.startX) / bounds.width;
    const dy = (event.clientY - drag.startY) / bounds.height;
    const start = drag.startRect;

    let next: CropRect = start;
    switch (drag.handle) {
      case 'move': {
        const width = start.right - start.left;
        const height = start.bottom - start.top;
        const left = clamp01(start.left + dx);
        const top = clamp01(start.top + dy);
        next = {
          left: Math.min(left, 1 - width),
          top: Math.min(top, 1 - height),
          right: Math.min(left, 1 - width) + width,
          bottom: Math.min(top, 1 - height) + height,
        };
        break;
      }
      case 'nw':
        next = { ...start, left: clamp01(start.left + dx), top: clamp01(start.top + dy) };
        break;
      case 'n':
        next = { ...start, top: clamp01(start.top + dy) };
        break;
      case 'ne':
        next = { ...start, right: clamp01(start.right + dx), top: clamp01(start.top + dy) };
        break;
      case 'e':
        next = { ...start, right: clamp01(start.right + dx) };
        break;
      case 'se':
        next = { ...start, right: clamp01(start.right + dx), bottom: clamp01(start.bottom + dy) };
        break;
      case 's':
        next = { ...start, bottom: clamp01(start.bottom + dy) };
        break;
      case 'sw':
        next = { ...start, left: clamp01(start.left + dx), bottom: clamp01(start.bottom + dy) };
        break;
      case 'w':
        next = { ...start, left: clamp01(start.left + dx) };
        break;
    }

    if (next.right - next.left < MIN_CROP_FRACTION || next.bottom - next.top < MIN_CROP_FRACTION) {
      return;
    }
    onChange(next);
  };

  const endDrag = (): void => {
    dragRef.current = null;
  };

  const HANDLE_POSITIONS: ReadonlyArray<{ readonly handle: Handle; readonly className: string }> = [
    { handle: 'nw', className: 'top-0 left-0 -translate-x-1/2 -translate-y-1/2 cursor-nwse-resize' },
    { handle: 'n', className: 'top-0 left-1/2 -translate-x-1/2 -translate-y-1/2 cursor-ns-resize' },
    { handle: 'ne', className: 'top-0 right-0 translate-x-1/2 -translate-y-1/2 cursor-nesw-resize' },
    { handle: 'e', className: 'top-1/2 right-0 translate-x-1/2 -translate-y-1/2 cursor-ew-resize' },
    { handle: 'se', className: 'bottom-0 right-0 translate-x-1/2 translate-y-1/2 cursor-nwse-resize' },
    { handle: 's', className: 'bottom-0 left-1/2 -translate-x-1/2 translate-y-1/2 cursor-ns-resize' },
    { handle: 'sw', className: 'bottom-0 left-0 -translate-x-1/2 translate-y-1/2 cursor-nesw-resize' },
    { handle: 'w', className: 'top-1/2 left-0 -translate-x-1/2 -translate-y-1/2 cursor-ew-resize' },
  ];

  return (
    <div ref={containerRef} className="absolute inset-0">
      <div
        role="group"
        aria-label="Crop region"
        onPointerMove={handlePointerMove}
        onPointerUp={endDrag}
        onPointerCancel={endDrag}
        onPointerDown={beginDrag('move')}
        className="absolute cursor-move border-2 border-[rgb(var(--mdui-color-primary))] bg-[rgb(var(--mdui-color-primary)/15%)]"
        style={{
          left: `${rect.left * 100}%`,
          top: `${rect.top * 100}%`,
          right: `${(1 - rect.right) * 100}%`,
          bottom: `${(1 - rect.bottom) * 100}%`,
        }}
      >
        {HANDLE_POSITIONS.map(({ handle, className }) => (
          <div
            key={handle}
            role="slider"
            aria-label={`Crop handle: ${handle}`}
            aria-valuenow={0}
            onPointerDown={(event) => {
              event.stopPropagation();
              beginDrag(handle)(event);
            }}
            onPointerMove={handlePointerMove}
            onPointerUp={endDrag}
            onPointerCancel={endDrag}
            className={`absolute h-4 w-4 rounded-full border-2 border-[rgb(var(--mdui-color-primary))] bg-[rgb(var(--mdui-color-surface))] ${className}`}
          />
        ))}
      </div>
    </div>
  );
}
