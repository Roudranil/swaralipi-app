import type { ReactElement } from 'react';
import { createBrowserRouter, RouterProvider } from 'react-router';

import App from './App';
import { LibraryScreen } from './features/library/LibraryScreen';
import { SettingsScreen } from './features/settings/SettingsScreen';

const router = createBrowserRouter([
  {
    path: '/',
    element: <App />,
    children: [
      { index: true, element: <LibraryScreen /> },
      { path: 'settings', element: <SettingsScreen /> },
    ],
  },
]);

export function AppRouter(): ReactElement {
  return <RouterProvider router={router} />;
}
