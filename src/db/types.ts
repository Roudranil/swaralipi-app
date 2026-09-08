/** Entity types for the Dexie schema. See docs/data-model.md. */

import type { CatppuccinSwatchName } from '../lib/catppuccin';

export type RotationDegrees = 0 | 90 | 180 | 270;
/** ISO A-series page presets a page can be fit into. `null` (on `RenderParams`) means no fitting. */
export type IsoPageSize = 'a3' | 'a4' | 'a5' | 'a6';

export interface CropRect {
  left: number;
  top: number;
  right: number;
  bottom: number;
}

/**
 * Non-destructive render pipeline applied at display time. Original blob is
 * never mutated. Pipeline order is crop -> rotate -> fit-into-page: `crop` is
 * always in the *original* image's coordinate space, so it survives later
 * rotation changes, and `pageSize` is declarative rather than an accumulated
 * transform, so switching presets re-derives from the original instead of
 * compounding. See docs/data-model.md §5.
 */
export interface RenderParams {
  rotationDegrees: RotationDegrees;
  crop: CropRect;
  pageSize: IsoPageSize | null;
}

export const DEFAULT_RENDER_PARAMS: RenderParams = {
  rotationDegrees: 0,
  crop: { left: 0, top: 0, right: 1, bottom: 1 },
  pageSize: null,
};

export type CustomFieldType = 'text' | 'number' | 'date' | 'boolean';
export type CustomFieldValue =
  | { type: 'text'; value: string }
  | { type: 'number'; value: number }
  | { type: 'date'; value: string }
  | { type: 'boolean'; value: boolean };

export interface Notation {
  id: string;
  title: string;
  artists: string[];
  dateWritten: string | null;
  timeSig: string | null;
  keySig: string | null;
  languages: string[];
  notes: string;
  tagIds: string[];
  instrumentInstanceIds: string[];
  customFields: Record<string, CustomFieldValue>;
  playCount: number;
  lastPlayedAt: string | null;
  createdAt: string;
  updatedAt: string;
  deletedAt: string | null;
}

export interface NotationPage {
  id: string;
  notationId: string;
  pageOrder: number;
  blobPath: string;
  renderParams: RenderParams;
  createdAt: string;
}

export interface Tag {
  id: string;
  name: string;
  colorHex: string;
  createdAt: string;
  updatedAt: string;
}

export interface InstrumentClass {
  id: string;
  name: string;
  createdAt: string;
  updatedAt: string;
}

export interface InstrumentInstance {
  id: string;
  classId: string;
  brand: string | null;
  model: string | null;
  colorHex: string;
  priceInr: number | null;
  photoBlobPath: string | null;
  notes: string;
  createdAt: string;
  updatedAt: string;
  deletedAt: string | null;
}

export interface CustomFieldDefinition {
  id: string;
  keyName: string;
  fieldType: CustomFieldType;
  createdAt: string;
  updatedAt: string;
}

/** A binary asset (page scan, instrument photo) keyed by an app-generated path string. */
export interface StoredBlob {
  path: string;
  blob: Blob;
}

export type ThemeMode = 'light' | 'dark' | 'system';
/**
 * `'catppuccin'` — seed color picked from the Catppuccin Latte/Mocha
 * palette (see `swatchSeeds()` in `src/lib/catppuccin.ts`). `'monet'` is
 * reserved for Android dynamic color from wallpaper; no plugin implements
 * it yet, so this value is currently unreachable.
 */
export type ColorSchemeMode = 'catppuccin' | 'monet';
export type DefaultSort =
  | 'createdAtDesc'
  | 'createdAtAsc'
  | 'dateWrittenDesc'
  | 'dateWrittenAsc'
  | 'titleAsc'
  | 'titleDesc'
  | 'playCountDesc'
  | 'lastPlayedAtDesc';

export interface UserPreferences {
  id: 1;
  userName: string;
  themeMode: ThemeMode;
  colorSchemeMode: ColorSchemeMode;
  seedColor: CatppuccinSwatchName;
  defaultSort: DefaultSort;
  defaultView: 'list';
}
