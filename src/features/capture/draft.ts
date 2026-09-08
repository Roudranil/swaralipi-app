/**
 * In-memory capture draft, held in a `useReducer` (no state library — see
 * CLAUDE.md). Nothing here touches Dexie; `notationPages.ts` only reads the
 * final draft on Save. See docs/modules/capture.md.
 */

import { DEFAULT_RENDER_PARAMS } from '../../db/types';
import type { CropRect, IsoPageSize, RenderParams, RotationDegrees } from '../../db/types';
import type { NormalizedImport } from './importImages';

export interface DraftPage {
  readonly id: string;
  readonly blob: Blob;
  readonly width: number;
  readonly height: number;
  readonly renderParams: RenderParams;
}

export interface CaptureDraft {
  readonly title: string;
  readonly artists: readonly string[];
  readonly dateWritten: string | null;
  readonly timeSig: string | null;
  readonly keySig: string | null;
  readonly pages: readonly DraftPage[];
  readonly activeIndex: number;
}

/** `dateWritten` seeds to today, per docs/ux-flows.md §6.1. */
export function initialDraft(today: string): CaptureDraft {
  return {
    title: '',
    artists: [],
    dateWritten: today,
    timeSig: null,
    keySig: null,
    pages: [],
    activeIndex: 0,
  };
}

export type DraftAction =
  | { readonly type: 'setField'; readonly field: 'title' | 'timeSig' | 'keySig'; readonly value: string }
  | { readonly type: 'setDateWritten'; readonly value: string | null }
  | { readonly type: 'setArtists'; readonly value: readonly string[] }
  | { readonly type: 'addPages'; readonly imports: readonly NormalizedImport[] }
  | { readonly type: 'deleteActivePage' }
  | { readonly type: 'reorderPages'; readonly from: number; readonly to: number }
  | { readonly type: 'setPageOrder'; readonly order: readonly string[] }
  | { readonly type: 'setActiveIndex'; readonly index: number }
  | { readonly type: 'stepActive'; readonly delta: -1 | 1 }
  | { readonly type: 'setCrop'; readonly crop: CropRect }
  | { readonly type: 'rotateActive'; readonly delta: -90 | 90 }
  | { readonly type: 'setPageSize'; readonly pageSize: IsoPageSize | null };

const ROTATION_STEPS: readonly RotationDegrees[] = [0, 90, 180, 270];

function clampIndex(index: number, length: number): number {
  if (length === 0) return 0;
  return Math.min(Math.max(index, 0), length - 1);
}

function updateActivePage(
  draft: CaptureDraft,
  update: (page: DraftPage) => DraftPage,
): CaptureDraft {
  const active = draft.pages[draft.activeIndex];
  if (!active) return draft;
  const pages = draft.pages.map((page, index) =>
    index === draft.activeIndex ? update(page) : page,
  );
  return { ...draft, pages };
}

/**
 * Pure reducer for the capture draft. Every action returns a new object —
 * no in-place mutation of `draft.pages` or its entries.
 */
export function draftReducer(draft: CaptureDraft, action: DraftAction): CaptureDraft {
  switch (action.type) {
    case 'setField':
      return { ...draft, [action.field]: action.value };

    case 'setDateWritten':
      return { ...draft, dateWritten: action.value };

    case 'setArtists':
      return { ...draft, artists: action.value };

    case 'addPages': {
      const newPages: DraftPage[] = action.imports.map((imported, i) => ({
        id: `${Date.now()}-${draft.pages.length + i}-${Math.random().toString(36).slice(2)}`,
        blob: imported.blob,
        width: imported.width,
        height: imported.height,
        renderParams: DEFAULT_RENDER_PARAMS,
      }));
      const pages = [...draft.pages, ...newPages];
      // if this is the first import, land on the first new page rather than
      // leaving activeIndex at 0-of-empty.
      const activeIndex = draft.pages.length === 0 ? 0 : draft.activeIndex;
      return { ...draft, pages, activeIndex };
    }

    case 'deleteActivePage': {
      const pages = draft.pages.filter((_, index) => index !== draft.activeIndex);
      return { ...draft, pages, activeIndex: clampIndex(draft.activeIndex, pages.length) };
    }

    case 'reorderPages': {
      const { from, to } = action;
      if (from === to || from < 0 || from >= draft.pages.length) return draft;
      const pages = [...draft.pages];
      const [moved] = pages.splice(from, 1);
      if (!moved) return draft;
      pages.splice(to, 0, moved);

      // follow the moved page if it was the active one; otherwise keep
      // pointing at whichever page was active, wherever it landed.
      const activePage = draft.pages[draft.activeIndex];
      const activeIndex = activePage ? pages.indexOf(activePage) : draft.activeIndex;
      return { ...draft, pages, activeIndex: clampIndex(activeIndex, pages.length) };
    }

    case 'setPageOrder': {
      // used to restore the pre-reorder order on "discard changes" — see
      // docs/modules/capture.md §4.2. `order` always comes from a snapshot
      // of this same draft's page ids, but the length check keeps a stale
      // snapshot (e.g. a page deleted mid-reorder) from silently dropping pages.
      const byId = new Map(draft.pages.map((page) => [page.id, page] as const));
      const pages = action.order.map((id) => byId.get(id)).filter((page): page is DraftPage => page !== undefined);
      if (pages.length !== draft.pages.length) return draft;
      const activePage = draft.pages[draft.activeIndex];
      const activeIndex = activePage ? pages.indexOf(activePage) : draft.activeIndex;
      return { ...draft, pages, activeIndex: clampIndex(activeIndex, pages.length) };
    }

    case 'setActiveIndex':
      return { ...draft, activeIndex: clampIndex(action.index, draft.pages.length) };

    case 'stepActive':
      return { ...draft, activeIndex: clampIndex(draft.activeIndex + action.delta, draft.pages.length) };

    case 'setCrop':
      return updateActivePage(draft, (page) => ({
        ...page,
        renderParams: { ...page.renderParams, crop: action.crop },
      }));

    case 'rotateActive':
      return updateActivePage(draft, (page) => {
        const currentStep = ROTATION_STEPS.indexOf(page.renderParams.rotationDegrees);
        const nextStep = (currentStep + (action.delta === 90 ? 1 : -1) + 4) % 4;
        const nextRotation = ROTATION_STEPS[nextStep] ?? 0;
        return { ...page, renderParams: { ...page.renderParams, rotationDegrees: nextRotation } };
      });

    case 'setPageSize':
      // always derives from the page's own crop/rotation, not the last
      // rendered size — pageSize is declarative, not accumulated.
      return updateActivePage(draft, (page) => ({
        ...page,
        renderParams: { ...page.renderParams, pageSize: action.pageSize },
      }));
  }
}
