import type { ReactElement } from 'react';
import { createBrowserRouter, RouterProvider } from 'react-router';

import App from './App';
import { LibraryScreen } from './features/library/LibraryScreen';
import { settingsRoutes } from './features/settings/settingsRoutes';
import { SettingsIndexScreen } from './features/settings/screens/SettingsIndexScreen';

const router = createBrowserRouter([
  {
    path: '/',
    element: <App />,
    children: [
      { index: true, element: <LibraryScreen /> },
      {
        path: 'settings',
        children: [{ index: true, element: <SettingsIndexScreen /> }, ...settingsRoutes()],
      },
    ],
  },
]);

export function AppRouter(): ReactElement {
  return <RouterProvider router={router} />;
}
