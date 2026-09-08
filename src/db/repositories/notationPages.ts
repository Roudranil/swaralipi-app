import { db } from '../db';
import { notationPagePath, putBlob } from '../blobStore';
import type { CaptureDraft } from '../../features/capture/draft';
import type { Notation, NotationPage } from '../types';

/**
 * Writes a notation and its pages from a finished capture draft, in one
 * transaction — a mid-write failure (e.g. a full IndexedDB quota) leaves
 * nothing behind rather than an orphaned notation with no pages. Fields the
 * capture screen doesn't collect (languages, tags, instruments, notes,
 * custom fields) are written as their empty defaults; editing them is a
 * separate future feature. See docs/modules/capture.md §5.
 */
export async function createNotationWithPages(draft: CaptureDraft): Promise<string> {
  const notationId = crypto.randomUUID();
  const now = new Date().toISOString();

  const notation: Notation = {
    id: notationId,
    title: draft.title.trim(),
    artists: [...draft.artists],
    dateWritten: draft.dateWritten,
    timeSig: draft.timeSig,
    keySig: draft.keySig,
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
  };

  const pages = draft.pages.map((draftPage, pageOrder) => ({
    row: {
      id: crypto.randomUUID(),
      notationId,
      pageOrder,
      blobPath: notationPagePath(notationId, draftPage.id),
      renderParams: draftPage.renderParams,
      createdAt: now,
    } satisfies NotationPage,
    blob: draftPage.blob,
  }));

  await db.transaction('rw', db.notations, db.notationPages, db.blobs, async () => {
    await db.notations.add(notation);
    for (const { row, blob } of pages) {
      await putBlob(row.blobPath, blob);
      await db.notationPages.add(row);
    }
  });

  return notationId;
}

/** Reads a notation's pages ordered by `pageOrder`. */
export async function pagesForNotation(notationId: string): Promise<NotationPage[]> {
  const pages = await db.notationPages.where('notationId').equals(notationId).toArray();
  return pages.sort((a, b) => a.pageOrder - b.pageOrder);
}
