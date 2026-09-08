import { useEffect, useState, type ReactElement } from 'react';

import type { DraftPage } from '../draft';

type PageCarouselProps = {
  readonly pages: readonly DraftPage[];
  readonly activeIndex: number;
  readonly onSelect: (index: number) => void;
};

/**
 * Horizontal thumbnail strip. The selected tile gets a `primary` ring (per
 * the plan: "same accent color" as the selection indicator elsewhere).
 * Thumbnails are the raw import blob with a CSS rotation hint applied —
 * approximate, not the full crop/page-fit render, since re-rendering every
 * thumbnail on every edit would be wasteful for a strip this size.
 */
export function PageCarousel({ pages, activeIndex, onSelect }: PageCarouselProps): ReactElement {
  const [urls, setUrls] = useState<readonly string[]>([]);

  useEffect(() => {
    // object URLs are an external-system resource (must be explicitly
    // revoked), not a value derivable during render, so this has to run in
    // an effect rather than during render.
    const next = pages.map((page) => URL.createObjectURL(page.blob));
    // oxlint-disable-next-line react/set-state-in-effect
    setUrls(next);
    return () => {
      for (const url of next) URL.revokeObjectURL(url);
    };
  }, [pages]);

  return (
    <div
      role="listbox"
      aria-label="Pages"
      className="flex gap-2 overflow-x-auto px-4 py-3"
      // centers when every thumbnail fits; falls back to start-aligned,
      // scrollable-from-position-0 once the strip overflows — see
      // ToolActionRow's `rowStyle` comment for why plain justify-center
      // doesn't work here.
      style={{ justifyContent: 'safe center' }}
    >
      {pages.map((page, index) => {
        const selected = index === activeIndex;
        return (
          <button
            key={page.id}
            type="button"
            role="option"
            aria-selected={selected}
            aria-label={`Page ${index + 1}`}
            onClick={() => onSelect(index)}
            className={`h-16 w-16 shrink-0 overflow-hidden rounded-md ${
              selected ? 'ring-2 ring-[rgb(var(--mdui-color-primary))]' : ''
            }`}
          >
            {urls[index] && (
              <img
                src={urls[index]}
                alt=""
                className="h-full w-full object-cover"
                style={{ transform: `rotate(${page.renderParams.rotationDegrees}deg)` }}
              />
            )}
          </button>
        );
      })}
    </div>
  );
}
