import { useLiveQuery } from 'dexie-react-hooks';
import type { ReactElement } from 'react';

import { activeNotations } from '../../db/repositories/notations';

export function LibraryScreen(): ReactElement {
  const notations = useLiveQuery(activeNotations, [], []);

  return (
    <div className="p-6">
      <h1 className="text-4xl font-bold">Hi, Musician</h1>
      {notations.length === 0 ? (
        <p className="mt-4 text-[rgb(var(--mdui-color-on-surface-variant))]">
          No notations yet. Capture your first page to get started.
        </p>
      ) : (
        <ul className="mt-4">
          {notations.map((notation) => (
            <li key={notation.id}>{notation.title}</li>
          ))}
        </ul>
      )}
    </div>
  );
}
