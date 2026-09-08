# Settings Module

## 1. Purpose and scope

`src/features/settings/` is the whole settings surface: the top-level
`/settings` list, every subscreen under it, and the extension point new
settings get added through. It exists so that adding a setting is "one
registry entry plus, if it needs one, one screen file" — never a router
edit, never a hand-written list row.

This doc is the contract for that extension point. `docs/ux-flows.md` §15–16
describes what the shipped screens look like to a user; this doc describes
how the module is built so the next entry follows the same shape.

## 2. Registry contract

Everything routes, lists, and summarizes from one file:
`src/features/settings/registry.ts`.

```ts
type SettingsEntryStatus = 'built' | 'planned';

type SettingsEntry = {
  readonly id: string;
  /** Path segment, relative to the parent entry (or to `/settings` at the top). */
  readonly path: string;
  readonly title: string;
  readonly icon: MaterialSymbol;
  readonly status: SettingsEntryStatus;
  /** Static secondary line. Ignored when `summary` is set. */
  readonly description?: string;
  /** Live secondary line, e.g. `"Dark, Mauve"`. Wins over `description`. */
  readonly summary?: (prefs: UserPreferences) => string;
  /** Leaf screen. Omit when `children` is set — a group screen is generated. */
  readonly Screen?: ComponentType;
  /** Nested subentries. Renders a generated group screen listing them. */
  readonly children?: ReadonlyArray<SettingsEntry>;
};

type SettingsSection = {
  readonly id: string;
  /** Omitted => divider only, no subheader — an unlabelled M3 group. */
  readonly label?: string;
  readonly entries: ReadonlyArray<SettingsEntry>;
};

export const SETTINGS_SECTIONS: ReadonlyArray<SettingsSection>;
```

Three properties make this the extension point:

1. **Nesting is free.** An entry with `children` and no `Screen` renders
   through the generated `SettingsGroupScreen`, which lists its children the
   same way the top-level list does. A future `appearance > motion speed`
   subentry is one nested object — no new screen file.
2. **Routes are derived, not hand-written.** `settingsRoutes.ts` walks the
   tree and turns each non-`planned` entry into a `react-router`
   `RouteObject`. A `status: 'planned'` entry yields no route at all, so a
   disabled row can never be reached by URL even by hand-typing it — the
   registry is the only gate.
3. **No cycles.** `registry.ts` imports leaf screens; screens never import
   the registry. `SettingsGroupScreen` receives its node as a prop from the
   route builder instead of importing the registry itself.

## 3. How to add a top-level entry

1. Write the screen component under `src/features/settings/screens/`,
   wrapped in `SettingsPage` (§5).
2. Add one `SettingsEntry` object to the relevant section (or a new section)
   in `registry.ts`, with `status: 'built'` and `Screen` pointing at it.
3. Nothing else. The row appears on `/settings`, and the route exists at
   `/settings/<path>` automatically.

To stage an entry ahead of building it (as most of the current registry
is), add the same object with `status: 'planned'` and no `Screen`. The row
appears dimmed and inert; flipping the status later is the only change
needed to make it live.

## 4. How to add a nested subentry

Give the parent entry a `children` array instead of a `Screen`:

```ts
{
  id: 'appearance',
  path: 'appearance',
  title: 'Appearance',
  icon: 'palette',
  status: 'built',
  children: [
    { id: 'motion', path: 'motion', title: 'Motion', icon: 'speed', status: 'planned' },
  ],
}
```

`settingsRoutes.ts` generates an index route at the parent's path
(`SettingsGroupScreen`, listing `children`) plus a route per built child.
No new screen file is needed until a child itself needs real content, at
which point it's step 1 of §3 applied one level down.

## 5. Shared component kit

`src/features/settings/components/`. This is where "one uniform look across
every settings screen" is enforced — each piece owns one visual rule so no
screen has to reinvent it.

| Component | Owns |
| --- | --- |
| `SettingsPage` | The app bar (back button when `onBack` is passed, title) and the 640px-capped, centred content column — the single place §6's layout rule lives |
| `SettingsRow` | One navigable list row: leading `<Icon>`, headline/description, trailing chevron, `useNavigate()` on click, `disabled` dimming for `planned` entries |
| `SettingsSection` | Divider + optional subheader + the `mdui-list` wrapper around a group of rows — the section rhythm every screen shares |
| `SettingsGroup` | A labelled group of *controls* inside a screen (not navigable rows) — used by Appearance for "Theme" and "Accent colour" |
| `SwatchGrid` | The Catppuccin accent-colour picker — docs/design-system.md §11.4 |

`SettingsGroupScreen` and `SettingsIndexScreen` (`screens/`) are the two
generated screens that consume `SettingsSection` + `SettingsRow` directly
from the registry; they are the only files that import `registry.ts`.

## 6. Layout rules

Phone (`< 840px`): each screen pushes over the one before it, with a back
arrow in `SettingsPage`'s app bar returning to the previous screen.

Laptop (`>= 840px`): the nav rail (`src/components/shell/NavRail.tsx`)
already owns the left edge of the window. A settings subscreen does **not**
open a second nav column beside it — no rail-plus-entry-list-plus-detail
three-pane layout. Instead the subscreen replaces the list exactly as it
does on phone, but `SettingsPage` caps its content at 640px and centres it
in the remaining space. This was chosen over two-pane list-detail because a
second always-visible nav column reads as competing with the rail at
840–1080px widths, and because centring is one CSS rule in one component
rather than a second router-aware layout to keep in sync.

## 7. Entry inventory

| Entry | Route | Status | State lives in |
| --- | --- | --- | --- |
| Personalisation | `/settings/personalisation` | Built | `preferences.userName` |
| Appearance | `/settings/appearance` | Built | `preferences.themeMode`, `preferences.seedColor` |
| Tags | `/settings/tags` | Planned | `db.tags` (repository not yet built) |
| Instruments | `/settings/instruments` | Planned | `db.instrumentClasses` / `instrumentInstances` |
| Library (default sort) | `/settings/library` | Planned | `preferences.defaultSort` |
| Custom fields | `/settings/custom-fields` | Planned | `db.customFieldDefs` |
| Trash | `/settings/trash` | Planned | `notations.deletedAt` |
| About | `/settings/about` | Built | none (reads `navigator.storage.estimate()`) |
| Open source licences | `/settings/licenses` | Planned | static content, no state |
| Backup and sync | `/settings/backup` | Planned | not designed yet |

## 8. Appearance spec

Two `SettingsGroup`s on one screen, in this order:

**Theme.** A single-select M3 segmented button
(`mdui-segmented-button-group selects="single" required`) with three
segments — Light / Dark / System, each an `<Icon>` in the segment's `icon`
slot plus a label. Its `change` event is a `CustomEvent` (`useCustomEvent`,
per docs/design-system.md §10 rule 1); the handler narrows the emitted value
with `isThemeMode()` (exported from `src/lib/themeBoot.ts`) and calls
`updatePreferences({ themeMode })`. Because the group's `value` HTML
attribute only seeds the *initial* selection (per mdui's own docs), external
changes — currently only Reset — are applied by writing the live `.value`
JS property through a ref in a `useEffect`, not by re-passing the attribute.

**Accent colour.** `SwatchGrid` over the 15-swatch Catppuccin set,
`onSelect` calling `updatePreferences({ seedColor })`. The grid's fill comes
from `useResolvedThemeMode(preferences.themeMode)`
(`src/hooks/useResolvedThemeMode.ts`), which resolves `'system'` to the
OS's live preference via `matchMedia`, so the picker's colours always match
what's actually painted.

**Reset.** A text button opens the docs/design-system.md §11.3 "Reset
appearance?" dialog; confirming restores `themeMode: 'system'` and
`seedColor: 'mauve'` (the same defaults `DEFAULT_PREFERENCES` uses).

No local mode/colour state exists anywhere on this screen — every control
writes straight to `preferences` via `updatePreferences()`, and
`useAppliedTheme()` (mounted once in `App.tsx`) reconciles the DOM as soon
as the write lands. There is nothing to keep in sync by hand.

Extending this screen for the appearance options already named as future
work (transition/animation speed, text size, default fonts, more colour
options) is one more `SettingsGroup` here for as long as there are a
handful; past that, promote `appearance` to use `children` (§4) so each
becomes its own subentry with no code restructuring.

## 9. Personalisation spec

One `SettingsGroup`, "Your name", with:

1. An `mdui-text-field`. Its `input` event is a `CustomEvent`
   (`useCustomEvent`); the field is not attribute-controlled per keystroke
   (only seeded once from `preferences.userName`) so nothing fights the
   caret while typing.
2. Validation in `src/features/settings/nameField.ts`:
   `validateName(draft)` — trimmed-empty is valid (means "no name set");
   otherwise must match `/^[\p{L}\p{M}]+$/u` (one word, letters plus
   combining marks so non-Latin scripts with vowel signs/virama — Bengali,
   Devanagari — validate correctly) and be at most `MAX_NAME_LENGTH` (24)
   characters.
3. `titleCaseName(draft)` runs on blur, not on every keystroke, writing the
   corrected text back into the field imperatively via its ref.
4. A live preview renders `greeting(draft)` — the exact same function
   (`src/lib/greeting.ts`) the Library screen calls, so the preview can
   never drift from what actually ships.
5. **Save** is a filled button, disabled while the draft is invalid or its
   title-cased form already equals the stored `userName`. On success:
   `updatePreferences({ userName })` plus a "Saved" snackbar
   (docs/design-system.md §11.2).

## 10. Accessibility contract

- Every settings row has a 48px minimum touch target (`mdui-list-item`'s own
  sizing) and is reachable by keyboard (native `mdui-list-item` tab order).
- `SwatchGrid` is `role="radiogroup"` with `role="radio" aria-checked` cells
  and `aria-label="<name>, selected|not selected"` — announces as a single-
  choice set, not a row of unrelated buttons (docs/design-system.md §11.4).
- The segmented button group's `required` attribute plus always having a
  value means "no selection" is never a reachable state.
- `planned` rows carry `disabled` on their `mdui-list-item`, which both dims
  them (contrast-safe per docs/design-system.md's 4.5:1 minimum) and
  disables their own interaction — screen readers announce them as disabled,
  not merely styled to look that way.
- Back buttons on subscreens are `mdui-button-icon` with `aria-label="Back"`
  and an `<Icon>` child rather than mdui's own `icon=` attribute, per
  docs/design-system.md §12.

## 11. Extension backlog

Known future settings, and where they land without restructuring anything
above:

- **Appearance**: transition/animation speed, text size, default fonts,
  additional colour source options — new `SettingsGroup`s on
  `AppearanceScreen`, or `children` on the `appearance` entry once there are
  more than a handful (§8, §4).
- **Personalisation**: a profile beyond the name field — deliberately left
  open; whatever it becomes is a second `SettingsGroup` on
  `PersonalisationScreen`.
- **Tags, Instruments, Library defaults, Custom fields, Trash, Open source
  licences, Backup and sync**: each is already a `status: 'planned'`
  registry entry (§7) with a reserved route; building one is §3's three
  steps against that existing entry.
