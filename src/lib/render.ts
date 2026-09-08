/**
 * Canvas I/O half of the render pipeline. `renderGeometry.ts` computes the
 * numbers; this module is the only place that touches `<canvas>`. See
 * docs/data-model.md §5 and docs/modules/capture.md.
 */

import type { RenderParams } from '../db/types';
import { croppedSize, fitInside, ISO_PAGE_PX, rotatedSize } from './renderGeometry';

/** A printed page is white in both light and dark mode — hardcoded, not themed. */
const PAGE_FILL = '#FFFFFF';

/**
 * Decodes a blob into a bitmap. `imageOrientation: 'from-image'` honours a
 * phone camera's EXIF rotation tag so the pixels come out upright before any
 * `RenderParams` rotation is applied on top.
 */
export function decodeImage(blob: Blob): Promise<ImageBitmap> {
  return createImageBitmap(blob, { imageOrientation: 'from-image' });
}

/**
 * Draws `src` under `params` (crop -> rotate -> fit-into-page) onto a new
 * canvas sized per `outputSize`. Rotation is done via canvas transform
 * rather than pixel manipulation, since it's always a multiple of 90deg.
 */
export function renderToCanvas(src: ImageBitmap, params: RenderParams): HTMLCanvasElement {
  const cropPx = {
    left: Math.round(params.crop.left * src.width),
    top: Math.round(params.crop.top * src.height),
    width: Math.round((params.crop.right - params.crop.left) * src.width),
    height: Math.round((params.crop.bottom - params.crop.top) * src.height),
  };
  const rotated = rotatedSize(
    croppedSize(src.width, src.height, params.crop),
    params.rotationDegrees,
  );

  // draw the cropped-and-rotated image onto an intermediate canvas first —
  // keeps the rotation transform math independent of whether a page fit
  // follows, rather than juggling both in one transform stack.
  const rotatedCanvas = document.createElement('canvas');
  rotatedCanvas.width = rotated.width;
  rotatedCanvas.height = rotated.height;
  const rotatedCtx = rotatedCanvas.getContext('2d');
  if (!rotatedCtx) throw new Error('2d canvas context unavailable');

  rotatedCtx.save();
  rotatedCtx.translate(rotated.width / 2, rotated.height / 2);
  rotatedCtx.rotate((params.rotationDegrees * Math.PI) / 180);
  rotatedCtx.drawImage(
    src,
    cropPx.left,
    cropPx.top,
    cropPx.width,
    cropPx.height,
    -cropPx.width / 2,
    -cropPx.height / 2,
    cropPx.width,
    cropPx.height,
  );
  rotatedCtx.restore();

  if (params.pageSize === null) return rotatedCanvas;

  const page = ISO_PAGE_PX[params.pageSize];
  const { size, offset } = fitInside(rotated, page);
  const pageCanvas = document.createElement('canvas');
  pageCanvas.width = page.width;
  pageCanvas.height = page.height;
  const pageCtx = pageCanvas.getContext('2d');
  if (!pageCtx) throw new Error('2d canvas context unavailable');

  pageCtx.fillStyle = PAGE_FILL;
  pageCtx.fillRect(0, 0, page.width, page.height);
  pageCtx.drawImage(rotatedCanvas, offset.x, offset.y, size.width, size.height);
  return pageCanvas;
}

/** Encodes the rendered canvas to a JPEG blob. */
export function renderToBlob(
  src: ImageBitmap,
  params: RenderParams,
  quality = 0.92,
): Promise<Blob> {
  const canvas = renderToCanvas(src, params);
  return new Promise((resolve, reject) => {
    canvas.toBlob(
      (blob) => (blob ? resolve(blob) : reject(new Error('canvas.toBlob returned null'))),
      'image/jpeg',
      quality,
    );
  });
}
