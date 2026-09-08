import { db } from '../db';
import { deleteBlob } from '../blobStore';
import type { Notation } from '../types';

/** Active (non-trashed) notations. */
export function activeNotations(): Promise<Notation[]> {
  return db.notations.filter((notation) => notation.deletedAt === null).toArray();
}

export function createNotation(notation: Notation): Promise<string> {
  return db.notations.add(notation);
}

export function softDeleteNotation(id: string): Promise<void> {
  return db.notations.update(id, { deletedAt: new Date().toISOString() }).then();
}

/** Removes a notation's pages, then their blobs, then the notation itself. Trash purge only. */
export async function purgeNotation(id: string): Promise<void> {
  const pages = await db.notationPages.where('notationId').equals(id).toArray();

  await db.transaction('rw', db.notationPages, db.blobs, db.notations, async () => {
    for (const page of pages) {
      await deleteBlob(page.blobPath);
      await db.notationPages.delete(page.id);
    }
    await db.notations.delete(id);
  });
}

/** Removes `tagId` from every notation that references it. Runs when a tag is deleted. */
export async function untagAllNotations(tagId: string): Promise<void> {
  const affected = await db.notations.where('tagIds').equals(tagId).toArray();
  await db.transaction('rw', db.notations, async () => {
    for (const notation of affected) {
      await db.notations.update(notation.id, {
        tagIds: notation.tagIds.filter((id) => id !== tagId),
      });
    }
  });
}
