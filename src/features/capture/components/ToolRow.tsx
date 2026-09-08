import type { ReactElement } from 'react';
import type { MaterialSymbol } from 'material-symbols';

import { Icon } from '../../../components/Icon';
import { TOOL_LABELS, type ToolMode } from '../toolMode';

type Tool = {
  readonly mode: Exclude<ToolMode, 'none'>;
  readonly icon: MaterialSymbol;
};

const TOOLS: readonly Tool[] = [
  { mode: 'crop', icon: 'crop' },
  { mode: 'rotate', icon: 'rotate_right' },
  { mode: 'resize', icon: 'aspect_ratio' },
  { mode: 'delete', icon: 'delete' },
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
    <div
      role="toolbar"
      aria-label="Page tools"
      // pinned to the bottom of the screen's flex column, same surface and
      // safe-area treatment as `NavBar` (docs/design-system.md §14) — but
      // shrink-0 rather than a fixed height, since this row's content wraps
      // to its own natural height instead of NavBar's fixed icon+label size.
      className="flex shrink-0 gap-2 overflow-x-auto border-t border-[rgb(var(--mdui-color-outline-variant))] bg-[rgb(var(--mdui-color-surface-container))] px-4 py-2 pb-[calc(0.5rem+env(safe-area-inset-bottom))]"
      style={{ justifyContent: 'safe center' }}
    >
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
            {TOOL_LABELS[tool.mode]}
          </button>
        );
      })}

      <button
        type="button"
        disabled={disabled}
        onClick={onReorder}
        className="flex shrink-0 flex-col items-center gap-1 rounded-md px-3 py-2 text-xs text-[rgb(var(--mdui-color-on-surface-variant))] disabled:opacity-40"
      >
        <Icon name="grid_view" />
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
