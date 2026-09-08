import type { ReactElement } from 'react';
import type { MaterialSymbol } from 'material-symbols';

import { Icon } from '../../../components/Icon';
import type { ToolMode } from '../toolMode';

type Tool = {
  readonly mode: ToolMode;
  readonly icon: MaterialSymbol;
  readonly label: string;
};

const TOOLS: readonly Tool[] = [
  { mode: 'crop', icon: 'crop', label: 'Crop' },
  { mode: 'rotate', icon: 'rotate_right', label: 'Rotate' },
  { mode: 'resize', icon: 'aspect_ratio', label: 'Resize' },
  { mode: 'delete', icon: 'delete', label: 'Delete' },
];

type ToolRowProps = {
  readonly activeMode: ToolMode;
  readonly disabled: boolean;
  readonly onSelect: (mode: ToolMode) => void;
  readonly onReorder: () => void;
  readonly onAddPages: () => void;
};

/**
 * Horizontally-scrolling per-page tool row. Reorder and add-pages aren't
 * `ToolMode`s — one opens `ReorderSheet`, the other opens the file picker
 * directly — so they're separate buttons rather than entries in `TOOLS`.
 * See docs/modules/capture.md §4.
 */
export function ToolRow({ activeMode, disabled, onSelect, onReorder, onAddPages }: ToolRowProps): ReactElement {
  return (
    <div role="toolbar" aria-label="Page tools" className="flex gap-2 overflow-x-auto px-4 py-2">
      {TOOLS.map((tool) => {
        const selected = activeMode === tool.mode;
        return (
          <button
            key={tool.mode}
            type="button"
            disabled={disabled}
            aria-pressed={selected}
            onClick={() => onSelect(selected ? 'none' : tool.mode)}
            className={`flex shrink-0 flex-col items-center gap-1 rounded-md px-3 py-2 text-xs disabled:opacity-40 ${
              selected
                ? 'bg-[rgb(var(--mdui-color-secondary-container))] text-[rgb(var(--mdui-color-on-secondary-container))]'
                : 'text-[rgb(var(--mdui-color-on-surface-variant))]'
            }`}
          >
            <Icon name={tool.icon} />
            {tool.label}
          </button>
        );
      })}

      <button
        type="button"
        disabled={disabled}
        onClick={onReorder}
        className="flex shrink-0 flex-col items-center gap-1 rounded-md px-3 py-2 text-xs text-[rgb(var(--mdui-color-on-surface-variant))] disabled:opacity-40"
      >
        <Icon name="reorder" />
        Reorder
      </button>

      <button
        type="button"
        onClick={onAddPages}
        className="flex shrink-0 flex-col items-center gap-1 rounded-md px-3 py-2 text-xs text-[rgb(var(--mdui-color-on-surface-variant))]"
      >
        <Icon name="add_photo_alternate" />
        Add pages
      </button>
    </div>
  );
}
