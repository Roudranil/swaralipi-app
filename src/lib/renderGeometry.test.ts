import { describe, expect, it } from 'vitest';

import type { RenderParams } from '../db/types';
import {
  fitInside,
  ISO_PAGE_PX,
  outputSize,
  rotateCropRect,
  unrotateCropRect,
} from './renderGeometry';

const FULL_CROP = { left: 0, top: 0, right: 1, bottom: 1 };
const HALF_CROP = { left: 0.25, top: 0.25, right: 0.75, bottom: 0.75 };

function params(overrides: Partial<RenderParams>): RenderParams {
  return { rotationDegrees: 0, crop: FULL_CROP, pageSize: null, ...overrides };
}

describe('outputSize', () => {
  it('returns the source size unchanged with no crop, rotation, or page fit', () => {
    expect(outputSize(1000, 500, params({}))).toEqual({ width: 1000, height: 500 });
  });

  it('applies a normalized crop before anything else', () => {
    expect(outputSize(1000, 500, params({ crop: HALF_CROP }))).toEqual({
      width: 500,
      height: 250,
    });
  });

  it('swaps width and height for a 90 or 270 degree rotation', () => {
    expect(outputSize(1000, 500, params({ rotationDegrees: 90 }))).toEqual({
      width: 500,
      height: 1000,
    });
    expect(outputSize(1000, 500, params({ rotationDegrees: 270 }))).toEqual({
      width: 500,
      height: 1000,
    });
  });

  it('leaves width and height as-is for a 180 degree rotation', () => {
    expect(outputSize(1000, 500, params({ rotationDegrees: 180 }))).toEqual({
      width: 1000,
      height: 500,
    });
  });

  it('composes crop then rotate before checking page size', () => {
    // 1000x500 cropped to the centre half -> 500x250, then rotated 90 -> 250x500.
    expect(
      outputSize(1000, 500, params({ crop: HALF_CROP, rotationDegrees: 90 })),
    ).toEqual({ width: 250, height: 500 });
  });

  it('a page size overrides crop/rotate output with the fixed preset dimensions', () => {
    expect(outputSize(1000, 500, params({ pageSize: 'a4' }))).toEqual(ISO_PAGE_PX.a4);
  });
});

describe('fitInside', () => {
  it('centres a landscape source inside a portrait page with horizontal bars', () => {
    const { size, offset } = fitInside({ width: 1000, height: 500 }, ISO_PAGE_PX.a4);
    // scale is bound by width: 1754/500 would overflow width, so width governs.
    const expectedScale = ISO_PAGE_PX.a4.width / 1000;
    expect(size).toEqual({
      width: Math.round(1000 * expectedScale),
      height: Math.round(500 * expectedScale),
    });
    expect(offset.x).toBe(0);
    // height is fully used or less than page height -> vertical offset is >= 0 and centred.
    expect(offset.y).toBe(Math.round((ISO_PAGE_PX.a4.height - size.height) / 2));
  });

  it('centres a portrait source inside a portrait page with even side bars', () => {
    const { size, offset } = fitInside({ width: 400, height: 1000 }, ISO_PAGE_PX.a4);
    expect(offset.x).toBe(Math.round((ISO_PAGE_PX.a4.width - size.width) / 2));
    expect(offset.y).toBe(Math.round((ISO_PAGE_PX.a4.height - size.height) / 2));
  });

  it('never upscales past the page bounds', () => {
    const { size } = fitInside({ width: 100, height: 100 }, ISO_PAGE_PX.a6);
    expect(size.width).toBeLessThanOrEqual(ISO_PAGE_PX.a6.width);
    expect(size.height).toBeLessThanOrEqual(ISO_PAGE_PX.a6.height);
  });
});

describe('rotateCropRect / unrotateCropRect', () => {
  const angles: Array<0 | 90 | 180 | 270> = [0, 90, 180, 270];

  it.each(angles)('round-trips a crop rect at %i degrees', (deg) => {
    const rotated = rotateCropRect(HALF_CROP, deg);
    expect(unrotateCropRect(rotated, deg)).toEqual(HALF_CROP);
  });

  it('maps an off-centre rect to the correct quadrant at 90 degrees', () => {
    // top-left quadrant of the original should land in the top-right of the 90-rotated view.
    const topLeft = { left: 0, top: 0, right: 0.5, bottom: 0.5 };
    expect(rotateCropRect(topLeft, 90)).toEqual({ left: 0.5, top: 0, right: 1, bottom: 0.5 });
  });

  it('180 degrees maps a rect to its point-reflected opposite', () => {
    const topLeft = { left: 0, top: 0, right: 0.5, bottom: 0.5 };
    expect(rotateCropRect(topLeft, 180)).toEqual({ left: 0.5, top: 0.5, right: 1, bottom: 1 });
  });

  it('a full-frame crop is rotation-invariant', () => {
    for (const deg of angles) {
      expect(rotateCropRect(FULL_CROP, deg)).toEqual(FULL_CROP);
    }
  });
});
