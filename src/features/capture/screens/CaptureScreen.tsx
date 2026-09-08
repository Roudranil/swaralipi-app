import 'mdui/components/button.js';
import 'mdui/components/button-icon.js';

import { useEffect, useReducer, useRef, useState, type ChangeEvent, type ReactElement } from 'react';
import { useNavigate } from 'react-router';

import { Icon } from '../../../components/Icon';
import { createNotationWithPages } from '../../../db/repositories/notationPages';
import { logError } from '../../../lib/log';
import { rotateCropRect, unrotateCropRect } from '../../../lib/renderGeometry';
import { draftReducer, initialDraft } from '../draft';
import { normalizeImports } from '../importImages';
import { CropOverlay } from '../components/CropOverlay';
import { MetadataHeader } from '../components/MetadataHeader';
import { MetadataPanel } from '../components/MetadataPanel';
import { PageCarousel } from '../components/PageCarousel';
import { PagePreview } from '../components/PagePreview';
import { ReorderSheet } from '../components/ReorderSheet';
import { ToolActionRow } from '../components/ToolActionRow';
import { ToolRow } from '../components/ToolRow';
import { TOOL_LABELS, type ToolMode } from '../toolMode';

const FULL_CROP = { left: 0, top: 0, right: 1, bottom: 1 };

function todayIsoDate(): string {
  return new Date().toISOString().slice(0, 10);
}

/**
 * Out-of-shell capture screen (`/capture`, sibling to `<App/>`, not a child
 * — see docs/architecture.md §5). One screen for the whole capture flow:
 * title + collapsible musical-basics panel, page preview, carousel, and the
 * crop/rotate/resize/reorder/delete tool row. See docs/modules/capture.md.
 */
export function CaptureScreen(): ReactElement {
  const navigate = useNavigate();
  const [draft, dispatch] = useReducer(draftReducer, todayIsoDate(), initialDraft);
  const [toolMode, setToolMode] = useState<ToolMode>('none');
  const [reorderOpen, setReorderOpen] = useState(false);
  // a one-shot pulse so PagePreview can spin the canvas into its new
  // orientation — see docs/modules/capture.md §5. `token` forces a new
  // effect run even if `delta` repeats (e.g. two "rotate left" in a row).
  const [rotationPulse, setRotationPulse] = useState<{ readonly delta: -90 | 90; readonly token: number } | null>(
    null,
  );
  // same one-shot-pulse shape, for the prev/next slide — see docs/modules/capture.md §5.
  const [stepPulse, setStepPulse] = useState<{ readonly direction: -1 | 1; readonly token: number } | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const openedPickerRef = useRef(false);
  // snapshot of page ids taken when ReorderSheet opens, so "discard changes"
  // can restore it — dragging dispatches `reorderPages` live, it isn't staged.
  const reorderSnapshotRef = useRef<readonly string[]>([]);
  // measured height of the carousel/options row, animated on a transition so
  // switching between the carousel and a tool's action row (different
  // natural heights) grows/shrinks PagePreview's space smoothly instead of
  // snapping — see the row wrapper below.
  const optionsRowRef = useRef<HTMLDivElement>(null);
  const [optionsRowHeight, setOptionsRowHeight] = useState<number | null>(null);

  // opens the device picker immediately when landing here with an empty
  // draft — the FAB's click just navigates, this is what actually imports.
  useEffect(() => {
    if (draft.pages.length === 0 && !openedPickerRef.current) {
      openedPickerRef.current = true;
      fileInputRef.current?.click();
    }
  }, [draft.pages.length]);

  const handleFilesPicked = (event: ChangeEvent<HTMLInputElement>): void => {
    // snapshot to a plain array before resetting `.value` — `event.target.files`
    // is a live FileList, so resetting the input's value clears it in place too.
    const files = Array.from(event.target.files ?? []);
    event.target.value = '';
    if (files.length === 0) return;
    normalizeImports(files)
      .then((imports) => dispatch({ type: 'addPages', imports }))
      .catch((error: unknown) => {
        logError('failed to import images', error);
      });
  };

  const activePage = draft.pages[draft.activeIndex];
  const canSave = draft.title.trim().length > 0 && draft.pages.length > 0;

  const handleRotate = (delta: -90 | 90): void => {
    dispatch({ type: 'rotateActive', delta });
    setRotationPulse({ delta, token: Date.now() });
  };

  const handleStep = (direction: -1 | 1): void => {
    dispatch({ type: 'stepActive', delta: direction });
    setStepPulse({ direction, token: Date.now() });
  };

  // deferred (not layout) + rAF, so the browser paints one frame at the *old*
  // height with the *new* content already swapped in (clipped by
  // overflow-hidden) before we measure and apply the new target height —
  // without that painted starting frame, the CSS transition below has
  // nothing to interpolate from and the height just snaps.
  useEffect(() => {
    const frame = requestAnimationFrame(() => {
      setOptionsRowHeight(optionsRowRef.current?.scrollHeight ?? null);
    });
    return () => cancelAnimationFrame(frame);
  }, [toolMode, draft.pages.length]);

  const openReorder = (): void => {
    reorderSnapshotRef.current = draft.pages.map((page) => page.id);
    setReorderOpen(true);
  };

  const closeReorderKeepingOrder = (): void => setReorderOpen(false);

  const closeReorderDiscardingOrder = (): void => {
    dispatch({ type: 'setPageOrder', order: reorderSnapshotRef.current });
    setReorderOpen(false);
  };

  const handleSave = (): void => {
    if (!canSave) return;
    createNotationWithPages(draft)
      .then(() => navigate('/'))
      .catch((error: unknown) => {
        logError('failed to save notation', error);
      });
  };

  return (
    <div className="mx-auto flex h-svh max-w-3xl flex-col overflow-hidden">
      <input
        ref={fileInputRef}
        type="file"
        accept="image/*"
        multiple
        className="hidden"
        onChange={handleFilesPicked}
        aria-hidden="true"
        tabIndex={-1}
      />

      <header className="flex items-center justify-between border-b border-[rgb(var(--mdui-color-outline-variant))] px-2 py-2">
        <mdui-button-icon aria-label="Discard and go back" onClick={() => navigate(-1)}>
          <Icon name="close" />
        </mdui-button-icon>
        <mdui-button variant="filled" disabled={!canSave} onClick={handleSave}>
          Save
        </mdui-button>
      </header>

      <MetadataHeader title={draft.title} onTitleChange={(value) => dispatch({ type: 'setField', field: 'title', value })}>
        <MetadataPanel
          artists={draft.artists}
          onArtistsChange={(artists) => dispatch({ type: 'setArtists', value: artists })}
          dateWritten={draft.dateWritten}
          onDateWrittenChange={(value) => dispatch({ type: 'setDateWritten', value })}
          timeSig={draft.timeSig}
          onTimeSigChange={(value) => dispatch({ type: 'setField', field: 'timeSig', value: value ?? '' })}
          keySig={draft.keySig}
          onKeySigChange={(value) => dispatch({ type: 'setField', field: 'keySig', value: value ?? '' })}
        />
      </MetadataHeader>

      {/* fills the space between the (fixed) header above and the (fixed)
          carousel/options row below, so PagePreview's own centering lands
          on the center of this remaining space, not the whole screen. */}
      <div className="min-h-0 flex-1">
        <PagePreview
          page={activePage}
          canStepBack={draft.activeIndex > 0}
          canStepForward={draft.activeIndex < draft.pages.length - 1}
          onStepBack={() => handleStep(-1)}
          onStepForward={() => handleStep(1)}
          rotationPulse={rotationPulse}
          stepPulse={stepPulse}
          renderOverride={
            toolMode === 'crop' && activePage
              ? { ...activePage.renderParams, crop: FULL_CROP, pageSize: null }
              : undefined
          }
          overlay={
            toolMode === 'crop' && activePage ? (
              <CropOverlay
                rect={rotateCropRect(activePage.renderParams.crop, activePage.renderParams.rotationDegrees)}
                onChange={(rect) =>
                  dispatch({
                    type: 'setCrop',
                    crop: unrotateCropRect(rect, activePage.renderParams.rotationDegrees),
                  })
                }
              />
            ) : undefined
          }
        />
      </div>

      {/* fixed padding above the carousel/options row, per the same gap
          convention as the hint row below it. */}
      <div className="h-4 shrink-0" aria-hidden="true" />

      {/* height-animated: see the rAF measurement effect above for why the
          transition needs a deferred, not layout, measurement. */}
      <div
        ref={optionsRowRef}
        className="shrink-0 overflow-hidden transition-[height] duration-[250ms] ease-out"
        style={{ height: optionsRowHeight ?? undefined }}
      >
        {toolMode === 'none' ? (
          <PageCarousel
            pages={draft.pages}
            activeIndex={draft.activeIndex}
            onSelect={(index) => dispatch({ type: 'setActiveIndex', index })}
          />
        ) : (
          <ToolActionRow
            mode={toolMode}
            currentPageSize={activePage?.renderParams.pageSize ?? null}
            onCropClear={() => {
              dispatch({ type: 'setCrop', crop: FULL_CROP });
              setToolMode('none');
            }}
            onCropSave={() => setToolMode('none')}
            onRotateLeft={() => handleRotate(-90)}
            onRotateRight={() => handleRotate(90)}
            onSetPageSize={(pageSize) => dispatch({ type: 'setPageSize', pageSize })}
            onKeep={() => setToolMode('none')}
            onDelete={() => {
              dispatch({ type: 'deleteActivePage' });
              setToolMode('none');
            }}
          />
        )}
      </div>

      {/* fixed padding above the toolbar — doubles as the "tap to close"
          hint while a tool mode is active, since closing it is just
          tapping that same tool's button again (ToolRow.tsx's toggle). */}
      <div className="flex h-8 shrink-0 items-center justify-center px-4 text-center text-xs text-[rgb(var(--mdui-color-on-surface-variant))]">
        {toolMode !== 'none' && <span>Tap the {TOOL_LABELS[toolMode]} button to close the menu</span>}
      </div>

      <ToolRow
        activeMode={toolMode}
        disabled={activePage === undefined}
        onSelect={setToolMode}
        onReorder={openReorder}
        onAddPages={() => fileInputRef.current?.click()}
      />

      {reorderOpen && (
        <ReorderSheet
          pages={draft.pages}
          onReorder={(from, to) => dispatch({ type: 'reorderPages', from, to })}
          onKeep={closeReorderKeepingOrder}
          onDiscard={closeReorderDiscardingOrder}
        />
      )}
    </div>
  );
}
