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
import type { ToolMode } from '../toolMode';

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
  const fileInputRef = useRef<HTMLInputElement>(null);
  const openedPickerRef = useRef(false);

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

  const handleSave = (): void => {
    if (!canSave) return;
    createNotationWithPages(draft)
      .then(() => navigate('/'))
      .catch((error: unknown) => {
        logError('failed to save notation', error);
      });
  };

  return (
    <div className="mx-auto flex h-svh max-w-3xl flex-col">
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

      <div className="relative flex-1 overflow-y-auto pb-4">
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

        <PagePreview
          page={activePage}
          canStepBack={draft.activeIndex > 0}
          canStepForward={draft.activeIndex < draft.pages.length - 1}
          onStepBack={() => dispatch({ type: 'stepActive', delta: -1 })}
          onStepForward={() => dispatch({ type: 'stepActive', delta: 1 })}
          rotationPulse={rotationPulse}
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

      <ToolRow
        activeMode={toolMode}
        disabled={activePage === undefined}
        onSelect={setToolMode}
        onReorder={() => setReorderOpen(true)}
        onAddPages={() => fileInputRef.current?.click()}
      />

      {reorderOpen && (
        <ReorderSheet
          pages={draft.pages}
          onReorder={(from, to) => dispatch({ type: 'reorderPages', from, to })}
          onClose={() => setReorderOpen(false)}
        />
      )}
    </div>
  );
}
