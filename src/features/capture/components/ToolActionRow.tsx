import type { ReactElement } from 'react';

import type { IsoPageSize } from '../../../db/types';
import type { ToolMode } from '../toolMode';

const PAGE_SIZE_OPTIONS: ReadonlyArray<{ readonly value: IsoPageSize | null; readonly label: string }> = [
  { value: null, label: 'Original' },
  { value: 'a3', label: 'A3' },
  { value: 'a4', label: 'A4' },
  { value: 'a5', label: 'A5' },
  { value: 'a6', label: 'A6' },
];

type ToolActionRowProps = {
  readonly mode: ToolMode;
  readonly currentPageSize: IsoPageSize | null;
  readonly onCropSave: () => void;
  readonly onCropClear: () => void;
  readonly onRotateLeft: () => void;
  readonly onRotateRight: () => void;
  readonly onSetPageSize: (size: IsoPageSize | null) => void;
  readonly onKeep: () => void;
  readonly onDelete: () => void;
};

const BUTTON_CLASS =
  'rounded-full px-4 py-2 text-sm font-medium bg-[rgb(var(--mdui-color-surface-container-high))] text-[rgb(var(--mdui-color-on-surface))]';
const SELECTED_CLASS =
  'rounded-full px-4 py-2 text-sm font-medium bg-[rgb(var(--mdui-color-secondary-container))] text-[rgb(var(--mdui-color-on-secondary-container))]';

/**
 * Replaces `PageCarousel` while a `ToolMode` other than `'none'` is active
 * (docs/modules/capture.md §4's mode table). Each mode gets its own fixed
 * set of actions rather than a generic "confirm/cancel" pair, since crop's
 * "no crop vs save cropped region" and delete's "keep vs delete" read
 * clearer as their own labelled buttons.
 */
export function ToolActionRow({
  mode,
  currentPageSize,
  onCropSave,
  onCropClear,
  onRotateLeft,
  onRotateRight,
  onSetPageSize,
  onKeep,
  onDelete,
}: ToolActionRowProps): ReactElement | null {
  if (mode === 'crop') {
    return (
      <div className="flex justify-center gap-2 px-4 py-2">
        <button type="button" className={BUTTON_CLASS} onClick={onCropClear}>
          No crop
        </button>
        <button type="button" className={BUTTON_CLASS} onClick={onCropSave}>
          Save cropped region
        </button>
      </div>
    );
  }

  if (mode === 'rotate') {
    return (
      <div className="flex justify-center gap-2 px-4 py-2">
        <button type="button" className={BUTTON_CLASS} onClick={onRotateLeft} aria-label="Rotate left 90 degrees">
          Rotate left
        </button>
        <button type="button" className={BUTTON_CLASS} onClick={onRotateRight} aria-label="Rotate right 90 degrees">
          Rotate right
        </button>
      </div>
    );
  }

  if (mode === 'resize') {
    return (
      <div className="flex gap-2 overflow-x-auto px-4 py-2">
        {PAGE_SIZE_OPTIONS.map((option) => (
          <button
            key={option.label}
            type="button"
            aria-pressed={currentPageSize === option.value}
            className={currentPageSize === option.value ? SELECTED_CLASS : BUTTON_CLASS}
            onClick={() => onSetPageSize(option.value)}
          >
            {option.label}
          </button>
        ))}
      </div>
    );
  }

  if (mode === 'delete') {
    return (
      <div className="flex justify-center gap-2 px-4 py-2">
        <button type="button" className={BUTTON_CLASS} onClick={onKeep}>
          Keep this image
        </button>
        <button
          type="button"
          className="rounded-full bg-[rgb(var(--mdui-color-error))] px-4 py-2 text-sm font-medium text-[rgb(var(--mdui-color-on-error))]"
          onClick={onDelete}
        >
          Delete this image
        </button>
      </div>
    );
  }

  return null;
}
