/**
 * Normalizes a freshly-picked image file before it ever enters the capture
 * draft: downscales to a sane long edge and re-encodes as JPEG, so a phone
 * camera's 10-20MB original never gets stored verbatim. See
 * docs/modules/capture.md.
 */

import { decodeImage } from '../../lib/render';

/** Long edge cap, in pixels, applied on import. */
export const MAX_LONG_EDGE = 2400;
export const JPEG_QUALITY = 0.85;

export interface NormalizedImport {
  readonly blob: Blob;
  readonly width: number;
  readonly height: number;
}

/**
 * Decodes `file`, downscales it so its longest edge is at most
 * `MAX_LONG_EDGE` (never upscales), and re-encodes as JPEG. Throws if `file`
 * is not an image the browser can decode.
 */
export async function normalizeImport(file: File): Promise<NormalizedImport> {
  if (!file.type.startsWith('image/')) {
    throw new Error(`"${file.name}" is not an image file`);
  }

  const bitmap = await decodeImage(file);
  const longEdge = Math.max(bitmap.width, bitmap.height);
  const scale = Math.min(1, MAX_LONG_EDGE / longEdge);
  const width = Math.round(bitmap.width * scale);
  const height = Math.round(bitmap.height * scale);

  const canvas = document.createElement('canvas');
  canvas.width = width;
  canvas.height = height;
  const ctx = canvas.getContext('2d');
  if (!ctx) throw new Error('2d canvas context unavailable');
  ctx.drawImage(bitmap, 0, 0, width, height);
  bitmap.close();

  const blob = await new Promise<Blob>((resolve, reject) => {
    canvas.toBlob(
      (result) => (result ? resolve(result) : reject(new Error('canvas.toBlob returned null'))),
      'image/jpeg',
      JPEG_QUALITY,
    );
  });

  return { blob, width, height };
}

/** Runs `normalizeImport` over every file, in order, skipping non-image entries. */
export async function normalizeImports(files: readonly File[]): Promise<NormalizedImport[]> {
  const results: NormalizedImport[] = [];
  for (const file of files) {
    if (!file.type.startsWith('image/')) continue;
    results.push(await normalizeImport(file));
  }
  return results;
}
