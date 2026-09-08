import { useEffect, useRef, type RefObject } from 'react';

/**
 * Binds a listener for a custom element's CustomEvent (e.g. mdui's `change`,
 * `input`, `open`, `close`). React 19's synthetic event system does not bind
 * to CustomEvents, so `onChange` on an `mdui-*` element typechecks but never
 * fires. See docs/design-system.md §2.6.
 *
 * `handler` is latched into a ref rather than the effect's dependency array
 * so passing an inline closure (the common case) doesn't tear down and
 * rebind the native listener on every render.
 */
export function useCustomEvent<TDetail = unknown>(
  ref: RefObject<HTMLElement | null>,
  eventName: string,
  handler: (event: CustomEvent<TDetail>) => void,
): void {
  const handlerRef = useRef(handler);

  useEffect(() => {
    handlerRef.current = handler;
  }, [handler]);

  useEffect(() => {
    const element = ref.current;
    if (!element) return;

    const listener = (event: Event): void => {
      handlerRef.current(event as CustomEvent<TDetail>);
    };

    element.addEventListener(eventName, listener);
    return () => element.removeEventListener(eventName, listener);
  }, [ref, eventName]);
}
