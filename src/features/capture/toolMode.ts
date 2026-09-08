/**
 * Which per-page tool is active. `'none'` shows the thumbnail carousel;
 * every other mode replaces it with that tool's action row
 * (`ToolActionRow`). Reorder and add-pages are not modes — see
 * `ToolRow.tsx`. See docs/modules/capture.md §4.
 */
export type ToolMode = 'none' | 'crop' | 'rotate' | 'resize' | 'delete';

/** Display label per non-`'none'` mode — shared by `ToolRow` and the "tap to close" hint in `CaptureScreen`. */
export const TOOL_LABELS: Record<Exclude<ToolMode, 'none'>, string> = {
  crop: 'Crop',
  rotate: 'Rotate',
  resize: 'Resize',
  delete: 'Delete',
};
