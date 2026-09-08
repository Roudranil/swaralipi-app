import { afterEach, describe, expect, it } from 'vitest';

import { db } from '../db';
import { DEFAULT_RENDER_PARAMS } from '../types';
import type { CaptureDraft, DraftPage } from '../../features/capture/draft';
import { purgeNotation } from './notations';
import { createNotationWithPages, pagesForNotation } from './notationPages';

function draftPage(id: string): DraftPage {
  return { id, blob: new Blob(['x']), width: 100, height: 200, renderParams: DEFAULT_RENDER_PARAMS };
}

function draft(overrides: Partial<CaptureDraft> = {}): CaptureDraft {
  return {
    title: 'Raag Yaman',
    artists: [],
    dateWritten: '2026-09-08',
    timeSig: null,
    keySig: null,
    pages: [draftPage('page-a'), draftPage('page-b')],
    activeIndex: 0,
    ...overrides,
  };
}

afterEach(async () => {
  await Promise.all([db.notations.clear(), db.notationPages.clear(), db.blobs.clear()]);
});

describe('createNotationWithPages', () => {
  it('writes the notation and a blob + page row per draft page, in order', async () => {
    const notationId = await createNotationWithPages(draft());

    const notation = await db.notations.get(notationId);
    expect(notation?.title).toBe('Raag Yaman');
    expect(notation?.deletedAt).toBeNull();

    const pages = await pagesForNotation(notationId);
    expect(pages).toHaveLength(2);
    expect(pages.map((p) => p.pageOrder)).toEqual([0, 1]);

    for (const page of pages) {
      expect(await db.blobs.get(page.blobPath)).toBeDefined();
    }
  });

  it('writes empty defaults for fields the capture screen does not collect', async () => {
    const notationId = await createNotationWithPages(draft());
    const notation = await db.notations.get(notationId);
    expect(notation?.languages).toEqual([]);
    expect(notation?.tagIds).toEqual([]);
    expect(notation?.instrumentInstanceIds).toEqual([]);
    expect(notation?.customFields).toEqual({});
    expect(notation?.playCount).toBe(0);
    expect(notation?.lastPlayedAt).toBeNull();
  });

  it('trims the title before writing it', async () => {
    const notationId = await createNotationWithPages(draft({ title: '  Raag Yaman  ' }));
    const notation = await db.notations.get(notationId);
    expect(notation?.title).toBe('Raag Yaman');
  });

  it('leaves nothing behind for a purge, same as any other notation', async () => {
    const notationId = await createNotationWithPages(draft());
    await purgeNotation(notationId);

    expect(await db.notations.get(notationId)).toBeUndefined();
    expect(await pagesForNotation(notationId)).toEqual([]);
  });
});
