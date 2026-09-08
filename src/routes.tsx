import type { ReactElement } from 'react';
import { createBrowserRouter, RouterProvider } from 'react-router';

import App from './App';
import { LibraryScreen } from './features/library/LibraryScreen';

const router = createBrowserRouter([
  {
    path: '/',
    element: <App />,
    children: [
      { index: true, element: <LibraryScreen /> },
      { path: 'settings', element: <div>Settings — not built yet</div> },
    ],
  },
]);

export function AppRouter(): ReactElement {
  return <RouterProvider router={router} />;
}
