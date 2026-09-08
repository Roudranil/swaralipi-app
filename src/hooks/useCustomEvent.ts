import { useEffect, type RefObject } from 'react';

/**
 * Binds a listener for a custom element's CustomEvent (e.g. mdui's `change`,
 * `input`, `open`, `close`). React 19's synthetic event system does not bind
 * to CustomEvents, so `onChange` on an `mdui-*` element typechecks but never
 * fires. See docs/design-system.md §2.6.
 */
export function useCustomEvent<TDetail = unknown>(
  ref: RefObject<HTMLElement | null>,
  eventName: string,
  handler: (event: CustomEvent<TDetail>) => void,
): void {
  useEffect(() => {
    const element = ref.current;
    if (!element) return;

    const listener = (event: Event): void => {
      handler(event as CustomEvent<TDetail>);
    };

    element.addEventListener(eventName, listener);
    return () => element.removeEventListener(eventName, listener);
  }, [ref, eventName, handler]);
}
