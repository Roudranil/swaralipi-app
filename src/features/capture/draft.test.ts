import { describe, expect, it } from 'vitest';

import { DEFAULT_RENDER_PARAMS } from '../../db/types';
import type { CaptureDraft, DraftPage } from './draft';
import { draftReducer, initialDraft } from './draft';
import type { NormalizedImport } from './importImages';

function page(id: string): DraftPage {
  return {
    id,
    blob: new Blob(['x']),
    width: 100,
    height: 200,
    renderParams: DEFAULT_RENDER_PARAMS,
  };
}

function draftWithPages(ids: readonly string[], activeIndex = 0): CaptureDraft {
  return { ...initialDraft('2026-09-08'), pages: ids.map(page), activeIndex };
}

function fakeImport(): NormalizedImport {
  return { blob: new Blob(['y']), width: 50, height: 50 };
}

describe('initialDraft', () => {
  it('seeds dateWritten to the given today and starts with no pages', () => {
    const draft = initialDraft('2026-09-08');
    expect(draft.dateWritten).toBe('2026-09-08');
    expect(draft.pages).toEqual([]);
    expect(draft.activeIndex).toBe(0);
  });
});

describe('addPages', () => {
  it('appends new pages in selection order', () => {
    const draft = draftWithPages(['a']);
    const imports = [fakeImport(), fakeImport()];
    const next = draftReducer(draft, { type: 'addPages', imports });
    expect(next.pages).toHaveLength(3);
    expect(next.pages[1]?.blob).toBe(imports[0]?.blob);
    expect(next.pages[2]?.blob).toBe(imports[1]?.blob);
  });

  it('lands on the first imported page when the draft started empty', () => {
    const draft = initialDraft('2026-09-08');
    const next = draftReducer(draft, { type: 'addPages', imports: [fakeImport()] });
    expect(next.activeIndex).toBe(0);
  });
});

describe('deleteActivePage', () => {
  it('removes the active page and clamps activeIndex when it was the last page', () => {
    const draft = draftWithPages(['a', 'b', 'c'], 2);
    const next = draftReducer(draft, { type: 'deleteActivePage' });
    expect(next.pages.map((p) => p.id)).toEqual(['a', 'b']);
    expect(next.activeIndex).toBe(1);
  });

  it('leaves activeIndex at 0 when the only page is deleted', () => {
    const draft = draftWithPages(['a'], 0);
    const next = draftReducer(draft, { type: 'deleteActivePage' });
    expect(next.pages).toEqual([]);
    expect(next.activeIndex).toBe(0);
  });
});

describe('reorderPages', () => {
  it('moves a page and follows it with activeIndex when it was the active page', () => {
    const draft = draftWithPages(['a', 'b', 'c', 'd'], 3); // 'd' active
    const next = draftReducer(draft, { type: 'reorderPages', from: 3, to: 1 });
    expect(next.pages.map((p) => p.id)).toEqual(['a', 'd', 'b', 'c']);
    expect(next.activeIndex).toBe(1);
  });

  it('keeps pointing at the same page when a different page moves', () => {
    const draft = draftWithPages(['a', 'b', 'c', 'd'], 0); // 'a' active
    const next = draftReducer(draft, { type: 'reorderPages', from: 3, to: 1 });
    expect(next.pages.map((p) => p.id)).toEqual(['a', 'd', 'b', 'c']);
    expect(next.activeIndex).toBe(0);
  });
});

describe('setPageSize', () => {
  it('replaces pageSize rather than compounding across successive calls', () => {
    const draft = draftWithPages(['a']);
    const afterA4 = draftReducer(draft, { type: 'setPageSize', pageSize: 'a4' });
    const afterA5 = draftReducer(afterA4, { type: 'setPageSize', pageSize: 'a5' });
    expect(afterA5.pages[0]?.renderParams.pageSize).toBe('a5');
    const backToA4 = draftReducer(afterA5, { type: 'setPageSize', pageSize: 'a4' });
    expect(backToA4.pages[0]?.renderParams).toEqual(afterA4.pages[0]?.renderParams);
  });
});

describe('rotateActive', () => {
  it('cycles through 0 -> 90 -> 180 -> 270 -> 0', () => {
    let draft = draftWithPages(['a']);
    const expected = [90, 180, 270, 0];
    for (const deg of expected) {
      draft = draftReducer(draft, { type: 'rotateActive', delta: 90 });
      expect(draft.pages[0]?.renderParams.rotationDegrees).toBe(deg);
    }
  });

  it('rotating left is the inverse of rotating right', () => {
    const draft = draftWithPages(['a']);
    const right = draftReducer(draft, { type: 'rotateActive', delta: 90 });
    const backToOriginal = draftReducer(right, { type: 'rotateActive', delta: -90 });
    expect(backToOriginal.pages[0]?.renderParams.rotationDegrees).toBe(0);
  });
});
