import { db } from './db';

/** Blob path convention for a notation page scan. */
export function notationPagePath(notationId: string, pageId: string): string {
  return `notations/${notationId}/pages/${pageId}.jpg`;
}

/** Stores a blob under `path`, overwriting any existing blob at that path. */
export async function putBlob(path: string, blob: Blob): Promise<void> {
  await db.blobs.put({ path, blob });
}

/** Reads a blob back. Returns `undefined` if nothing is stored at `path`. */
export async function getBlob(path: string): Promise<Blob | undefined> {
  const stored = await db.blobs.get(path);
  return stored?.blob;
}

export async function deleteBlob(path: string): Promise<void> {
  await db.blobs.delete(path);
}

/**
 * Reads a blob and wraps it in an object URL for use in `<img src>`.
 * Callers must call `URL.revokeObjectURL` (e.g. on unmount) to avoid leaking memory.
 */
export async function getBlobObjectUrl(path: string): Promise<string | undefined> {
  const blob = await getBlob(path);
  return blob ? URL.createObjectURL(blob) : undefined;
}
