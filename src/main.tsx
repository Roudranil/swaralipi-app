import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';

import { AppRouter } from './routes';
import { applyTheme } from './lib/theme';
import { DEFAULT_SEED_LIGHT } from './lib/catppuccin';
import './styles/index.css';

applyTheme(DEFAULT_SEED_LIGHT);

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <AppRouter />
  </StrictMode>,
);
