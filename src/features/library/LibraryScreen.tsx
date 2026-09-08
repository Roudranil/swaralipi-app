import { useLiveQuery } from 'dexie-react-hooks';
import type { ReactElement } from 'react';
import { useNavigate } from 'react-router';

import { AppBar } from '../../components/AppBar';
import { Fab } from '../../components/Fab';
import { activeNotations } from '../../db/repositories/notations';
import { greeting } from '../../lib/greeting';
import { usePreferences } from '../../hooks/usePreferences';

export function LibraryScreen(): ReactElement {
  const notations = useLiveQuery(activeNotations, [], []);
  const preferences = usePreferences();
  const navigate = useNavigate();

  return (
    <>
      <AppBar>
        <mdui-top-app-bar-title>{greeting(preferences.userName)}</mdui-top-app-bar-title>
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
      {/* laptop width mounts the FAB in NavRail instead — see Fab.tsx. */}
      <Fab
        icon="add"
        label="Add notation"
        extended
        onClick={() => navigate('/capture')}
        className="fixed right-4 bottom-[calc(5rem+env(safe-area-inset-bottom)+1rem)] z-20 md:hidden"
      />
    </>
  );
}
