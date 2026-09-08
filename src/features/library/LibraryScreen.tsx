import { useLiveQuery } from 'dexie-react-hooks';
import type { ReactElement } from 'react';

import { AppBar } from '../../components/AppBar';
import { activeNotations } from '../../db/repositories/notations';

export function LibraryScreen(): ReactElement {
  const notations = useLiveQuery(activeNotations, [], []);

  return (
    <>
      <AppBar>
        <mdui-top-app-bar-title>Hi, Musician</mdui-top-app-bar-title>
      </AppBar>
      <div className="p-6">
        {notations.length === 0 ? (
          <p className="text-[rgb(var(--mdui-color-on-surface-variant))]">
            No notations yet. Capture your first page to get started.
          </p>
        ) : (
          <ul>
            {notations.map((notation) => (
              <li key={notation.id}>{notation.title}</li>
            ))}
          </ul>
        )}
      </div>
    </>
  );
}
