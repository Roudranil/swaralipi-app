import { afterEach, describe, expect, it } from 'vitest';

import { db } from '../db';
import { getBlob, putBlob } from '../blobStore';
import { activeNotations, purgeNotation, untagAllNotations } from './notations';
import { DEFAULT_RENDER_PARAMS, type Notation, type NotationPage } from '../types';

const now = new Date().toISOString();

function makeNotation(overrides: Partial<Notation> = {}): Notation {
  return {
    id: 'notation-1',
    title: 'Raag Yaman',
    artists: [],
    dateWritten: null,
    timeSig: null,
    keySig: null,
    languages: [],
    notes: '',
    tagIds: [],
    instrumentInstanceIds: [],
    customFields: {},
    playCount: 0,
    lastPlayedAt: null,
    createdAt: now,
    updatedAt: now,
    deletedAt: null,
    ...overrides,
  };
}

function makePage(overrides: Partial<NotationPage> = {}): NotationPage {
  return {
    id: 'page-1',
    notationId: 'notation-1',
    pageOrder: 0,
    blobPath: 'notations/notation-1/page_1.jpg',
    renderParams: DEFAULT_RENDER_PARAMS,
    createdAt: now,
    ...overrides,
  };
}

afterEach(async () => {
  await Promise.all([db.notations.clear(), db.notationPages.clear(), db.blobs.clear()]);
});

describe('activeNotations', () => {
  it('excludes soft-deleted notations', async () => {
    await db.notations.bulkAdd([
      makeNotation({ id: 'active', deletedAt: null }),
      makeNotation({ id: 'trashed', deletedAt: now }),
    ]);

    const result = await activeNotations();

    expect(result.map((n) => n.id)).toEqual(['active']);
  });
});

describe('purgeNotation', () => {
  it('deletes the notation, its pages, and their blobs', async () => {
    await db.notations.add(makeNotation());
    await db.notationPages.add(makePage());
    await putBlob('notations/notation-1/page_1.jpg', new Blob(['x']));

    await purgeNotation('notation-1');

    expect(await db.notations.get('notation-1')).toBeUndefined();
    expect(await db.notationPages.get('page-1')).toBeUndefined();
    expect(await getBlob('notations/notation-1/page_1.jpg')).toBeUndefined();
  });
});

describe('untagAllNotations', () => {
  it('removes a tag id from every notation that references it', async () => {
    await db.notations.bulkAdd([
      makeNotation({ id: 'a', tagIds: ['tag-1', 'tag-2'] }),
      makeNotation({ id: 'b', tagIds: ['tag-2'] }),
    ]);

    await untagAllNotations('tag-1');

    expect((await db.notations.get('a'))?.tagIds).toEqual(['tag-2']);
    expect((await db.notations.get('b'))?.tagIds).toEqual(['tag-2']);
  });
});
