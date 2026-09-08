import 'mdui/components/navigation-bar.js';
import 'mdui/components/navigation-bar-item.js';
import 'mdui/components/navigation-rail.js';
import 'mdui/components/navigation-rail-item.js';
import 'mdui/components/navigation-drawer.js';
import 'mdui/components/list.js';
import 'mdui/components/list-item.js';
import 'mdui/components/top-app-bar.js';
import 'mdui/components/top-app-bar-title.js';

import { useRef, type ReactElement } from 'react';
import { Outlet, useLocation, useNavigate } from 'react-router';

import { useBreakpoint } from './hooks/useBreakpoint';
import { useCustomEvent } from './hooks/useCustomEvent';

const NAV_ITEMS = [
  { value: '/', label: 'Library', icon: 'library_music_outlined' },
  { value: '/settings', label: 'Settings', icon: 'settings_outlined' },
];

/** Adaptive app shell. Nav swaps bar -> rail -> drawer at the M3 breakpoints. */
export default function App(): ReactElement {
  const layout = useBreakpoint();
  const navigate = useNavigate();
  const location = useLocation();
  const navRef = useRef<HTMLElement | null>(null);

  useCustomEvent(navRef, 'change', () => {
    const value = (navRef.current as unknown as { value?: string })?.value;
    if (value) navigate(value);
  });

  const activeValue = location.pathname === '/' ? '/' : location.pathname;

  if (layout === 'bar') {
    return (
      <div className="flex min-h-svh flex-col">
        <main className="flex-1 pb-16">
          <Outlet />
        </main>
        <mdui-navigation-bar
          ref={navRef as never}
          value={activeValue}
          className="fixed bottom-0 left-0 right-0"
        >
          {NAV_ITEMS.map((item) => (
            <mdui-navigation-bar-item key={item.value} value={item.value} icon={item.icon}>
              {item.label}
            </mdui-navigation-bar-item>
          ))}
        </mdui-navigation-bar>
      </div>
    );
  }

  if (layout === 'rail') {
    return (
      <div className="flex min-h-svh">
        <mdui-navigation-rail ref={navRef as never} value={activeValue}>
          {NAV_ITEMS.map((item) => (
            <mdui-navigation-rail-item key={item.value} value={item.value} icon={item.icon}>
              {item.label}
            </mdui-navigation-rail-item>
          ))}
        </mdui-navigation-rail>
        <main className="flex-1">
          <Outlet />
        </main>
      </div>
    );
  }

  return (
    <div className="flex min-h-svh">
      <mdui-navigation-drawer ref={navRef as never} open modal={false}>
        <mdui-list>
          {NAV_ITEMS.map((item) => (
            <mdui-list-item
              key={item.value}
              icon={item.icon}
              active={item.value === activeValue}
              onClick={() => navigate(item.value)}
            >
              {item.label}
            </mdui-list-item>
          ))}
        </mdui-list>
      </mdui-navigation-drawer>
      <main className="flex-1">
        <Outlet />
      </main>
    </div>
  );
}
