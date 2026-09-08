/**
 * Pure geometry for the notation-page render pipeline (crop -> rotate ->
 * fit-into-page). No DOM/canvas access here on purpose, so this is
 * unit-testable without a browser canvas — `src/lib/render.ts` is the
 * canvas-touching counterpart that consumes these functions. See
 * docs/data-model.md §5 and docs/modules/capture.md.
 */

import type { CropRect, IsoPageSize, RenderParams, RotationDegrees } from '../db/types';

export interface Size {
  readonly width: number;
  readonly height: number;
}

export interface Point {
  readonly x: number;
  readonly y: number;
}

// portrait pixel dimensions at 150dpi, chosen so no preset upscales a
// 2400px-long-edge import (see `importImages.ts`'s MAX_LONG_EDGE).
export const ISO_PAGE_PX: Record<IsoPageSize, Size> = {
  a3: { width: 1754, height: 2480 },
  a4: { width: 1240, height: 1754 },
  a5: { width: 874, height: 1240 },
  a6: { width: 620, height: 874 },
};

/** Pixel size of a normalized crop rect against a `w x h` source image. */
export function croppedSize(w: number, h: number, crop: CropRect): Size {
  return {
    width: Math.round((crop.right - crop.left) * w),
    height: Math.round((crop.bottom - crop.top) * h),
  };
}

/** Swaps width/height for a 90 or 270 degree rotation; passes through unchanged at 0/180. */
export function rotatedSize({ width, height }: Size, deg: RotationDegrees): Size {
  return deg === 90 || deg === 270 ? { width: height, height: width } : { width, height };
}

/**
 * Largest `w x h` box that fits inside `page` with aspect ratio preserved,
 * plus its centred offset within `page` — the offset is where the caller
 * draws the scaled source so the remaining area (drawn white) forms an even
 * border, not a corner gap.
 */
export function fitInside(size: Size, page: Size): { size: Size; offset: Point } {
  const scale = Math.min(page.width / size.width, page.height / size.height);
  const fitted: Size = {
    width: Math.round(size.width * scale),
    height: Math.round(size.height * scale),
  };
  return {
    size: fitted,
    offset: {
      x: Math.round((page.width - fitted.width) / 2),
      y: Math.round((page.height - fitted.height) / 2),
    },
  };
}

/**
 * Final output pixel dimensions of a `w x h` source under `params`, walking
 * the same crop -> rotate -> fit-into-page pipeline the canvas renderer
 * applies. `pageSize: null` means no page fitting — output is just the
 * cropped-and-rotated size.
 */
export function outputSize(w: number, h: number, params: RenderParams): Size {
  const cropped = croppedSize(w, h, params.crop);
  const rotated = rotatedSize(cropped, params.rotationDegrees);
  if (params.pageSize === null) return rotated;
  return ISO_PAGE_PX[params.pageSize];
}

/**
 * Maps a normalized crop rect from the *original* image's coordinate space
 * into the coordinate space of the image as displayed after `deg` rotation
 * — used to draw the crop overlay over a rotated preview. Inverse of
 * `unrotateCropRect`. Only 90-degree steps, so this is four fixed cases
 * rather than a general matrix.
 */
export function rotateCropRect(c: CropRect, deg: RotationDegrees): CropRect {
  switch (deg) {
    case 0:
      return c;
    case 90:
      // (x, y) -> (1-y, x)
      return { left: 1 - c.bottom, top: c.left, right: 1 - c.top, bottom: c.right };
    case 180:
      return { left: 1 - c.right, top: 1 - c.bottom, right: 1 - c.left, bottom: 1 - c.top };
    case 270:
      // (x, y) -> (y, 1-x)
      return { left: c.top, top: 1 - c.right, right: c.bottom, bottom: 1 - c.left };
  }
}

/**
 * Inverse of `rotateCropRect` — maps a crop rect drawn over the rotated
 * preview back into the original image's coordinate space for storage.
 */
export function unrotateCropRect(c: CropRect, deg: RotationDegrees): CropRect {
  const inverse: Record<RotationDegrees, RotationDegrees> = { 0: 0, 90: 270, 180: 180, 270: 90 };
  return rotateCropRect(c, inverse[deg]);
}
