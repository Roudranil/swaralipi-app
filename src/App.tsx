import { useState, type ReactElement } from 'react';
import { Outlet } from 'react-router';

import { NavBar } from './components/shell/NavBar';
import { NavRail } from './components/shell/NavRail';
import { SCROLL_TARGET_ID } from './components/shell/scrollTarget';
import { useAppliedTheme } from './hooks/useAppliedTheme';

/**
 * App shell: nav (bottom bar on phone, collapsible rail on laptop) +
 * `<Outlet/>`. The tier switch is pure CSS (`md:` at the 840px breakpoint in
 * `src/styles/index.css`) — both navs always render, so `<main>` never
 * remounts and routed screen state survives a resize across the breakpoint.
 */
export default function App(): ReactElement {
  useAppliedTheme();
  const [railExpanded, setRailExpanded] = useState(false);

  return (
    <div className="grid h-svh grid-rows-[1fr_auto] overflow-hidden md:grid-cols-[auto_1fr] md:grid-rows-[1fr]">
      <NavRail expanded={railExpanded} onToggle={() => setRailExpanded((value) => !value)} />
      {/* min-w-0: without it a wide child would push this grid column past
          the rail's width instead of scrolling internally. */}
      <main id={SCROLL_TARGET_ID} className="min-w-0 overflow-y-auto">
        <Outlet />
      </main>
      <NavBar />
    </div>
  );
}
