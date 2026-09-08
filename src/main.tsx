import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
// `?url` gives the hashed build URL so we can preload it — the font itself
// loads via the `@import` in styles/index.css, this just requests it early.
import materialSymbolsRoundedFontUrl from 'material-symbols/material-symbols-rounded.woff2?url';

import { AppRouter } from './routes';
import { applyTheme } from './lib/theme';
import { DEFAULT_SEED_LIGHT } from './lib/catppuccin';
import './styles/index.css';

/**
 * Preloads the default (Rounded) icon font. `mdui.css` and material-symbols
 * both set `font-display: block`, so without a preload hint icons render as
 * invisible boxes for a beat on cold load instead of falling back to text.
 */
function preloadDefaultIconFont(): void {
  const link = document.createElement('link');
  link.rel = 'preload';
  link.as = 'font';
  link.type = 'font/woff2';
  link.crossOrigin = 'anonymous';
  link.href = materialSymbolsRoundedFontUrl;
  document.head.appendChild(link);
}

preloadDefaultIconFont();
applyTheme(DEFAULT_SEED_LIGHT);

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <AppRouter />
  </StrictMode>,
);
