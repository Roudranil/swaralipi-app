import 'mdui/components/text-field.js';
import 'mdui/components/chip.js';

import { useRef, type KeyboardEvent, type ReactElement } from 'react';

import { useCustomEvent } from '../../../hooks/useCustomEvent';

type MetadataPanelProps = {
  readonly artists: readonly string[];
  readonly onArtistsChange: (artists: readonly string[]) => void;
  readonly dateWritten: string | null;
  readonly onDateWrittenChange: (value: string | null) => void;
  readonly timeSig: string | null;
  readonly onTimeSigChange: (value: string | null) => void;
  readonly keySig: string | null;
  readonly onKeySigChange: (value: string | null) => void;
};

const COMMIT_KEYS = new Set(['Enter', ',']);

/**
 * Musical-basics fields collapsed under `MetadataHeader`'s chevron. Only the
 * fields already on `Notation` (`src/db/types.ts`) — languages, tags,
 * instruments, notes, and custom fields are deliberately out of scope for
 * this screen (see docs/modules/capture.md §2).
 */
export function MetadataPanel({
  artists,
  onArtistsChange,
  dateWritten,
  onDateWrittenChange,
  timeSig,
  onTimeSigChange,
  keySig,
  onKeySigChange,
}: MetadataPanelProps): ReactElement {
  const artistInputRef = useRef<HTMLElement & { value: string }>(null);
  const chipListRef = useRef<HTMLDivElement>(null);
  const timeSigRef = useRef<HTMLElement & { value: string }>(null);
  const keySigRef = useRef<HTMLElement & { value: string }>(null);

  // `input` is a CustomEvent on mdui-text-field — see docs/design-system.md §10 item 1.
  useCustomEvent(timeSigRef, 'input', () => {
    onTimeSigChange(timeSigRef.current?.value || null);
  });
  useCustomEvent(keySigRef, 'input', () => {
    onKeySigChange(keySigRef.current?.value || null);
  });

  // mdui-chip's delete icon fires a `delete` CustomEvent, not a native click
  // — delegate one listener on the wrapping list rather than one per chip.
  useCustomEvent(chipListRef, 'delete', (event) => {
    const chip = event.target as HTMLElement | null;
    const index = chip?.dataset.index;
    if (index === undefined) return;
    onArtistsChange(artists.filter((_, i) => i !== Number(index)));
  });

  const commitArtist = (): void => {
    const value = artistInputRef.current?.value.trim();
    if (!value) return;
    onArtistsChange([...artists, value]);
    if (artistInputRef.current) artistInputRef.current.value = '';
  };

  const handleArtistKeyDown = (event: KeyboardEvent): void => {
    if (!COMMIT_KEYS.has(event.key)) return;
    event.preventDefault();
    commitArtist();
  };

  return (
    <div className="flex flex-col gap-3 pb-2">
      <div>
        <div ref={chipListRef} className="mb-2 flex flex-wrap gap-1" role="list" aria-label="Artists">
          {artists.map((artist, index) => (
            <mdui-chip key={`${artist}-${index}`} variant="input" deletable data-index={index}>
              {artist}
            </mdui-chip>
          ))}
        </div>
        <mdui-text-field
          ref={artistInputRef}
          label="Artist(s)"
          helper="Comma or Enter adds an artist"
          onBlur={commitArtist}
          onKeyDown={handleArtistKeyDown}
        />
      </div>

      <input
        type="date"
        aria-label="Date written"
        value={dateWritten ?? ''}
        onChange={(event) => onDateWrittenChange(event.target.value || null)}
        className="rounded-md border border-[rgb(var(--mdui-color-outline-variant))] bg-transparent px-3 py-2 text-[rgb(var(--mdui-color-on-surface))]"
      />

      <mdui-text-field
        ref={timeSigRef}
        label="Time signature"
        placeholder="e.g. 4/4, 6/8, free"
        value={timeSig ?? ''}
      />

      <mdui-text-field
        ref={keySigRef}
        label="Key signature"
        placeholder="e.g. C major, Yaman"
        value={keySig ?? ''}
      />
    </div>
  );
}
