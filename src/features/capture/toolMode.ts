/**
 * Which per-page tool is active. `'none'` shows the thumbnail carousel;
 * every other mode replaces it with that tool's action row
 * (`ToolActionRow`). Reorder and add-pages are not modes — see
 * `ToolRow.tsx`. See docs/modules/capture.md §4.
 */
export type ToolMode = 'none' | 'crop' | 'rotate' | 'resize' | 'delete';
