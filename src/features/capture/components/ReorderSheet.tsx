import {
  closestCenter,
  DndContext,
  KeyboardSensor,
  PointerSensor,
  useSensor,
  useSensors,
  type DragEndEvent,
} from '@dnd-kit/core';
import {
  rectSortingStrategy,
  SortableContext,
  sortableKeyboardCoordinates,
  useSortable,
} from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import { useEffect, useState, type ReactElement } from 'react';

import { useCatppuccinPalette } from '../../../hooks/useCatppuccinPalette';
import type { DraftPage } from '../draft';

type ReorderSheetProps = {
  readonly pages: readonly DraftPage[];
  readonly onReorder: (from: number, to: number) => void;
  /** Closes and keeps whatever order dragging left the pages in. */
  readonly onKeep: () => void;
  /** Restores the order captured when the sheet opened, then closes. */
  readonly onDiscard: () => void;
};

type TileProps = {
  readonly page: DraftPage;
  readonly pageNumber: number;
};

/** One draggable grid tile. Thumbnail is the raw import blob — see `PageCarousel` for why. */
function Tile({ page, pageNumber }: TileProps): ReactElement {
  const { attributes, listeners, setNodeRef, transform, transition, isDragging } = useSortable({
    id: page.id,
  });
  const [url, setUrl] = useState<string | undefined>(undefined);

  useEffect(() => {
    // object URLs are an external-system resource (must be explicitly
    // revoked) — see the identical case in PageCarousel.tsx.
    const objectUrl = URL.createObjectURL(page.blob);
    // oxlint-disable-next-line react/set-state-in-effect
    setUrl(objectUrl);
    return () => URL.revokeObjectURL(objectUrl);
  }, [page.blob]);

  return (
    <div
      ref={setNodeRef}
      {...attributes}
      {...listeners}
      style={{ transform: CSS.Transform.toString(transform), transition }}
      className={`flex flex-col items-center gap-1 rounded-md p-1 ${isDragging ? 'opacity-50' : ''}`}
    >
      <div className="aspect-square w-full overflow-hidden rounded-md bg-[rgb(var(--mdui-color-surface-container-high))]">
        {url && <img src={url} alt="" className="h-full w-full object-cover" />}
      </div>
      <span className="text-sm text-[rgb(var(--mdui-color-on-surface-variant))]">{pageNumber}</span>
    </div>
  );
}

/**
 * Drag-to-reorder grid ("like Adobe Scanner"): 2 columns on phone, 4 on
 * laptop, with pages shifting by one as a tile moves. `KeyboardSensor` keeps
 * reorder reachable without a pointer. Floats as a centered dialog sized to
 * exactly 4 columns on `md:` and up; fills the screen on phone, where a
 * floating card would leave awkward margins. See docs/modules/capture.md §4.2.
 */
export function ReorderSheet({ pages, onReorder, onKeep, onDiscard }: ReorderSheetProps): ReactElement {
  const { colors, onColorClassName } = useCatppuccinPalette();
  const sensors = useSensors(
    useSensor(PointerSensor),
    useSensor(KeyboardSensor, { coordinateGetter: sortableKeyboardCoordinates }),
  );

  const handleDragEnd = (event: DragEndEvent): void => {
    const { active, over } = event;
    if (!over || active.id === over.id) return;
    const from = pages.findIndex((page) => page.id === active.id);
    const to = pages.findIndex((page) => page.id === over.id);
    if (from === -1 || to === -1) return;
    onReorder(from, to);
  };

  return (
    <div
      role="dialog"
      aria-label="Reorder pages"
      className="fixed inset-0 z-30 flex items-center justify-center bg-[rgb(var(--mdui-color-scrim))]/50 md:p-6"
    >
      <div className="flex h-full w-full flex-col bg-[rgb(var(--mdui-color-surface))] md:h-auto md:max-h-[85vh] md:w-fit md:rounded-2xl md:shadow-xl">
        <header className="flex items-center justify-center border-b border-[rgb(var(--mdui-color-outline-variant))] px-4 py-3">
          <h2 className="text-lg font-medium">Reorder pages</h2>
        </header>

        <div className="flex-1 overflow-y-auto p-4">
          <DndContext sensors={sensors} collisionDetection={closestCenter} onDragEnd={handleDragEnd}>
            <SortableContext items={pages.map((page) => page.id)} strategy={rectSortingStrategy}>
              {/* mobile: flexible fr columns filling the full-screen sheet.
                  md+: fixed 6rem columns, so the grid's own width — and the
                  dialog's `md:w-fit` around it — is exactly 4 tiles wide. */}
              <div className="grid w-full grid-cols-2 gap-3 md:w-fit md:grid-cols-[repeat(4,6rem)]">
                {pages.map((page, index) => (
                  <Tile key={page.id} page={page} pageNumber={index + 1} />
                ))}
              </div>
            </SortableContext>
          </DndContext>
        </div>

        <div className="flex shrink-0 gap-3 border-t border-[rgb(var(--mdui-color-outline-variant))] px-4 py-3 pb-[calc(0.75rem+env(safe-area-inset-bottom))]">
          <button
            type="button"
            className={`flex-1 rounded-full py-2 text-sm font-medium ${onColorClassName}`}
            style={{ backgroundColor: colors.green }}
            onClick={onKeep}
          >
            Keep changes
          </button>
          <button
            type="button"
            className={`flex-1 rounded-full py-2 text-sm font-medium ${onColorClassName}`}
            style={{ backgroundColor: colors.red }}
            onClick={onDiscard}
          >
            Discard changes
          </button>
        </div>
      </div>
    </div>
  );
}
