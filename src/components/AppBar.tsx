import 'mdui/components/top-app-bar.js';
import 'mdui/components/top-app-bar-title.js';

import type { ReactElement, ReactNode } from 'react';

import { SCROLL_TARGET_ID } from './shell/scrollTarget';

type AppBarVariant = 'small' | 'center-aligned' | 'medium' | 'large';

type AppBarProps = {
  readonly children: ReactNode;
  /** mdui top-app-bar variant. Defaults to `"small"`. */
  readonly variant?: AppBarVariant;
};

/**
 * Screen-owned top app bar. Each screen renders its own — the shell only
 * supplies the scroll container (`#app-main`) that `scroll-target` points
 * at, per the plan's decision that the app bar is per-screen, not
 * shell-owned.
 *
 * `scroll-target` is mandatory: without it mdui listens on `window`, which
 * never scrolls in this layout (`<main>` is the scroller), so
 * `scroll-behavior="elevate"` would silently do nothing.
 *
 * `sticky top-0` overrides mdui's `:host{position:fixed}` /
 * `:host([scroll-target]){position:absolute}` rules, which both assume the
 * bar floats over content rather than sitting in normal flow above it.
 *
 * `bg-[...surface-container...]` overrides mdui's default `:host` background
 * (`surface`, same as the page) — per docs/design-system.md §3 the app bar
 * is `surface-container`, distinct from the screen behind it. Without this
 * the bar has no visible boundary against its own content.
 */
export function AppBar({ children, variant = 'small' }: AppBarProps): ReactElement {
  return (
    <mdui-top-app-bar
      variant={variant}
      scroll-behavior="elevate"
      scroll-target={`#${SCROLL_TARGET_ID}`}
      className="sticky top-0 z-10 bg-[rgb(var(--mdui-color-surface-container))]"
    >
      {children}
    </mdui-top-app-bar>
  );
}
