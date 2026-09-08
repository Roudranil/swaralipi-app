import 'mdui/components/text-field.js';
import 'mdui/components/button-icon.js';

import { useRef, useState, type ReactElement, type ReactNode } from 'react';

import { Icon } from '../../../components/Icon';
import { useCustomEvent } from '../../../hooks/useCustomEvent';

type MetadataHeaderProps = {
  readonly title: string;
  readonly onTitleChange: (value: string) => void;
  readonly children: ReactNode;
};

/**
 * Top of the capture screen: a centred, required title field plus a chevron
 * that expands `children` (the musical-basics panel) below it. Collapsed by
 * default — most captures don't need it. See docs/modules/capture.md §2.
 */
export function MetadataHeader({ title, onTitleChange, children }: MetadataHeaderProps): ReactElement {
  const [panelOpen, setPanelOpen] = useState(false);
  const inputRef = useRef<HTMLElement & { value: string }>(null);

  // `input` is a CustomEvent on mdui-text-field — see docs/design-system.md §10 item 1.
  useCustomEvent(inputRef, 'input', () => {
    onTitleChange(inputRef.current?.value ?? '');
  });

  return (
    <div className="mx-auto flex w-full max-w-md flex-col gap-2 px-4 pt-4">
      <div className="flex items-center gap-2">
        <mdui-text-field
          ref={inputRef}
          className="flex-1"
          label="Title"
          value={title}
          required
          helper="Required"
        />
        <mdui-button-icon
          aria-label={panelOpen ? 'Hide details' : 'Show details'}
          onClick={() => setPanelOpen((open) => !open)}
        >
          <Icon name={panelOpen ? 'keyboard_arrow_up' : 'keyboard_arrow_down'} />
        </mdui-button-icon>
      </div>
      {panelOpen && children}
    </div>
  );
}
