# Design System

## 1. Overview

Material 3 (M3), split into two independent layers. Either can be replaced
without touching the other.

- **Components** — `mdui@2.1.5`. Classic M3 (2021 spec), complete adaptive
  navigation set, Lit-based custom elements.
- **Color** — `@material/material-color-utilities@0.4.0`. 2025 Expressive
  color spec, official Google, 175k downloads/week.

Google's official `@material/web` was rejected: it is in maintenance mode
since 2024-06 and ships **no navigation bar, rail, drawer, top app bar, card,
or snackbar**. There is no official M3 Expressive implementation for the web
anywhere — Expressive shipped Android/Compose first.

## 2. Why the split

MDUI reads its own `--mdui-color-*` CSS variables (RGB channel triplets,
e.g. `103, 80, 164`), generated internally from `material-color-utilities`
0.3.0 at the 2021 spec — missing every `surfaceContainer*`, `surfaceDim`,
`surfaceBright`, `surfaceTint`, and `*Fixed` token.

`src/lib/theme.ts` generates the same variable names ourselves at the 2025
spec (`SchemeTonalSpot` + `MaterialDynamicColors`, **not** the legacy
`themeFromSourceColor` / `applyTheme` path) and writes them to `:root`,
overriding MDUI's generator. One source of truth.

**Never call MDUI's `setColorScheme()`.** It overwrites our tokens with
2021-spec values.

Theme switching uses MDUI's `mdui-theme-light` / `mdui-theme-dark` /
`mdui-theme-auto` classes on `<html>`; our generated stylesheet defines both
variable sets and the classes flip between them. `applyThemeMode()` in
`src/lib/theme.ts` is what sets that class (and mirrors it to
`documentElement.style.colorScheme`) — never call MDUI's own theming
function for this.

## 3. Color role assignments

All values consumed as `rgb(var(--mdui-color-<token>))`.

| UI purpose | Token |
| --- | --- |
| Screen background | `surface` |
| App bar background | `surface-container` |
| Bottom navigation background | `surface-container` |
| FAB background | `primary-container` |
| FAB icon | `on-primary-container` |
| Card fill (default) | `surface-container-low` |
| Card border (outlined variant) | `outline-variant` |
| Primary action button fill | `primary` |
| Primary action button text | `on-primary` |
| Tonal button fill | `secondary-container` |
| Tonal button text | `on-secondary-container` |
| Swipe-left Edit badge | `secondary-container` |
| Swipe-left Delete badge | `error-container` |
| Search bar fill | `surface-container-high` |
| Active filter chip fill | `secondary-container` |
| Active filter chip text | `on-secondary-container` |
| Inactive chip fill | `surface` |
| Inactive chip border | `outline` |
| Snackbar background | `inverse-surface` |
| Snackbar text | `on-inverse-surface` |
| Divider | `outline-variant` |
| Secondary / caption text | `on-surface-variant` |
| Active filter banner | `tertiary-container` |
| Archived instrument badge | `error-container` |
| Destructive action text | `error` |

## 4. Catppuccin palette

- **Tags** — color picked from Catppuccin; chip background = Catppuccin color
  at 20% opacity (inactive), 15% opacity + outline (active)
- **Instrument instance** — Catppuccin color -> 4px left-border accent on the
  list row
- **Appearance seed swatches** — full Catppuccin Latte (light) and Mocha
  (dark) palettes
- **No free-form color pickers anywhere in the app**

The seed is persisted as a Catppuccin **swatch name** (`preferences.seedColor`,
e.g. `'mauve'`), not a hex — Latte and Mocha use different hexes for the same
swatch, so a stored hex can't survive a mode switch. `swatchSeeds(name)` in
`src/lib/catppuccin.ts` resolves one name to both hexes; `applyTheme()` in
`src/lib/theme.ts` always generates both the `-light` (Latte) and `-dark`
(Mocha) token sets from that pair, and the `mdui-theme-*` class picks the
active one in pure CSS. Default seed: Mauve (`#8839EF` Latte /
`#CBA6F7` Mocha). Both palettes live in `src/lib/catppuccin.ts`, ported
verbatim.

## 5. Typography

| UI element | Type scale | Weight | Notes |
| --- | --- | --- | --- |
| Library greeting "Hi, \<name\>" | `display-small` | Bold | Hero text |
| App bar titles | `title-large` | Regular | |
| Notation title (Detail) | `headline-medium` | SemiBold | |
| Notation title (List row) | `title-medium` | Medium | |
| Artist name | `body-medium` | Regular | `on-surface-variant` |
| Metadata labels | `label-large` | Medium | |
| Metadata values | `body-small` | Regular | |
| Chip text | `label-medium` | Medium | |
| Button text | `label-large` | Medium | |
| Snackbar text | `body-medium` | Regular | on `inverse-surface` |
| Caption / secondary info | `body-small` | Regular | `on-surface-variant` |
| Settings row title | `body-large` | Regular | |
| Settings row subtitle | `body-small` | Regular | `on-surface-variant` |
| Recently Played section label | `label-large` | Medium | `on-surface-variant` |
| Filter / sort sheet title | `title-medium` | Medium | |
| Empty state headline | `headline-small` | Regular | |
| Empty state body | `body-medium` | Regular | `on-surface-variant` |

Mapped to MDUI's `--mdui-typescale-<token>-*` variables.

## 6. Shape

| Component | Corner radius | Tailwind token |
| --- | --- | --- |
| Cards | 12px | `--radius-md` |
| Notation row thumbnail | 8px | `--radius-sm` |
| Page editor image preview | 12px | `--radius-md` |
| Recently Played carousel card | 12px | `--radius-md` |
| FAB | 16px | `--radius-lg` |
| Buttons | full | `--radius-full` |
| Chips | full | `--radius-full` |
| Dialogs | 28px | `--radius-xl` |
| Bottom sheets | 28px top, 0 bottom | `--radius-xl` |
| Snackbar | 4px | `--radius-xs` |
| Search bar | full | `--radius-full` |
| Instrument instance photo | 8px | `--radius-sm` |
| Catppuccin color picker circle | full | `--radius-full` |

Defined in `src/styles/index.css` `@theme`, overriding MDUI's classic
2021-spec `--mdui-shape-corner-*` tokens — this is the Expressive gap-closer
for shape.

## 7. Elevation

| Surface | Level | Tonal offset |
| --- | --- | --- |
| Screen background | 0 | None |
| Cards at rest | 1 | +5% primary |
| App bar (scrolled) | 2 | +8% primary |
| Navigation bar | 2 | +8% primary |
| FAB | 3 | +11% primary |
| Dialogs | 3 | +11% primary |
| Bottom sheets (modal) | 3 | +11% primary |
| Bottom sheets (standard) | 1 | +5% primary |
| Fanned page stack — bottom layers | 1 | +5% primary |

Mapped to `--mdui-elevation-level*`.

## 8. Motion

### 8.1 Screen transitions

| Transition | Easing | Duration |
| --- | --- | --- |
| Push — enter | decelerate emphasized | 400ms |
| Push — exit | ease-in | 200ms |
| Pop — enter | ease-out | 250ms |
| Pop — exit | accelerate emphasized | 200ms |

### 8.2 Component motion

| Component | Behavior | Duration |
| --- | --- | --- |
| Bottom sheet slide-up | ease-out-cubic | 300ms |
| Bottom sheet dismiss | ease-in-cubic | 200ms |
| Player chrome fade | opacity transition | 300ms |
| Snackbar entry | ease-out-cubic | 250ms |
| Snackbar exit | ease-in-cubic | 200ms |
| Filter chip toggle | spring (mass 1, stiffness 800, damping 80) | ~300ms |
| Swipe action reveal | linear, follows finger | — |
| FAB collapse (scroll down) | same spring | ~250ms |
| FAB expand (scroll up) | same spring | ~250ms |
| Active filter banner appear | opacity + scale | 200ms |

The spring is approximated as a CSS `linear()` easing curve,
`--ease-spring` in `src/styles/index.css` `@theme`.

## 9. Known MDUI gaps and their fills

| Missing | Fill |
| --- | --- |
| Date picker | `<input type="date">`, styled |
| Bottom sheet | `mdui-navigation-drawer placement="bottom"`, or a Tailwind sheet |
| Search bar | `mdui-text-field` + `mdui-menu` |
| Safe-area insets | Add `env(safe-area-inset-*)` padding ourselves |
| Icon font | MDUI's `icon=`/`active-icon=` attributes resolve against the legacy `'Material Icons'` font, which we don't ship — see §12. Use `<Icon>` in the `icon`/`active-icon` slot instead |

## 10. React integration rules

1. **Custom events need refs.** React 19 passes props to custom elements
   correctly, but its synthetic event system does not bind to a custom
   element's `CustomEvent`. `onChange` on an `mdui-slider` typechecks and
   silently does nothing. Native bubbling events (`click`, `focus`, `blur`,
   `keydown`) work as normal props. Everything else (`change`, `input`,
   `open`, `opened`, `close`, `closed`, `invalid`, `clear`) needs
   `ref` + `addEventListener` — use `src/hooks/useCustomEvent.ts`.
2. **Shadow DOM is a hard wall.** Tailwind classes on an `mdui-*` tag style
   only the host element. Internals are reachable only via exposed custom
   properties, `::part()`, and slots.

Typings: `/// <reference types="mdui/jsx.en.d.ts" />` in `src/vite-env.d.ts`.
Import order: `mdui/mdui.css` before the Tailwind entry, so Tailwind wins on
source order. Cherry-pick component imports
(`import 'mdui/components/button.js'`) to keep the PWA payload small.

## 11. Reusable component patterns

### 11.1 Empty states

| Screen | Icon | Headline | CTA |
| --- | --- | --- | --- |
| Library (no notations) | `library_music` | "No notations yet" | "Capture" |
| Search (no results) | `search_off` | "No matches" | Clear filters |
| Tags (none created) | `sell` | "No tags yet" | "+ Create" |
| Trash (empty) | `delete` | "Trash is empty" | — |

Names are Material Symbols (§12) — the outline/rounded/sharp silhouette is a
CSS class and `FILL` axis, not part of the name, so no `_outlined` suffix.

### 11.2 Snackbar triggers

| Trigger | Message | Action |
| --- | --- | --- |
| Notation moved to trash | "Moved to trash" | Undo |
| Notation restored | "Restored" | — |
| Tag deleted | "Tag deleted" | Undo |
| Instrument archived | "Archived" | Undo |
| Trash emptied | "Trash emptied" | — |
| Save failed | "Couldn't save. Try again." | Retry |
| Offline | "You're offline. Changes saved locally." | — |
| Name saved | "Saved" | — |

### 11.3 Dialog patterns

| Dialog | Title | Actions |
| --- | --- | --- |
| Delete notation (permanent, from Trash) | "Delete forever?" | Cancel / Delete |
| Delete tag | "Delete tag?" | Cancel / Delete |
| Delete instrument class (blocked) | "Class in use" | OK |
| Discard unsaved edits | "Discard changes?" | Cancel / Discard |
| Empty trash | "Empty trash?" | Cancel / Empty |
| Reset appearance to default | "Reset appearance?" | Cancel / Reset |

### 11.4 Catppuccin color picker

36px tappable circles inside a 48px hit target, check indicator on the
selected swatch, `aria-label="<color name>, <selected/not selected>"`.
Implemented once, in `src/features/settings/components/SwatchGrid.tsx`
(the Appearance accent-colour picker — docs/modules/settings.md §8), for
reuse by any future free-standing Catppuccin picker (tags, instrument
colour):

- The circle grid is `role="radiogroup"`; each circle is `role="radio"
  aria-checked`, not a native `<input type="radio">`, since the visual is a
  custom-painted circle. This is what makes it announce as a single-choice
  set rather than a row of unrelated buttons.
- Circle fill is read from whichever palette (Latte/Mocha) is actually
  painted right now, not from the stored theme mode directly — under
  `system` mode this can differ from the mode last written to
  `preferences.themeMode` if the OS preference has since changed live.
- The check mark's colour is chosen per resolved mode (light check on
  Latte's dark hexes, dark check on Mocha's light hexes), not per-swatch
  luminance — every hex in each palette clears the same contrast threshold,
  so the cheaper mode-level rule is sufficient.

### 11.5 Chip input field

Comma commits a chip. Fuzzy tag suggestions via Fuse.js as the user types.
Error outline on invalid input.

### 11.6 Error states

Screen-level (full-screen error + retry), inline (form field error text),
and snackbar (transient, non-blocking) — pick the narrowest scope that fits
the failure.

### 11.7 Settings list rows

Every settings screen — the top-level list and any nested group screen —
renders through the same three components in
`src/features/settings/components/`, so the rhythm is identical everywhere:

- **`SettingsSection`**: one `mdui-divider` (omitted for the first section on
  a screen) followed by an `mdui-list`, with an optional `mdui-list-subheader`
  when the section has a `label`. A section can still omit `label` and rely
  on the divider alone — every current top-level section happens to have
  one ("Housekeeping", "Miscellaneous", etc.), but a single-entry section
  that doesn't warrant a subheader is free to skip it.
- **`SettingsRow`**: one `mdui-list-item`, `rounded`, with an `<Icon>` in the
  `icon` slot, `headline`/`description` for the two typography rows (§5
  "Settings row title" / "Settings row subtitle"), and a `chevron_right`
  `<Icon>` in the `end-icon` slot. Tapping calls `useNavigate()` — never
  `href`, which would render a real `<a>` and force a full page load out of
  the SPA.
- **`status: 'planned'` rows** render with `disabled` set on the
  `mdui-list-item`, which both dims the row (M3's standard disabled
  treatment) and disables its own click handling; the row's `onClick` is
  additionally never wired to `navigate()` in this state, so a planned
  entry is inert two ways over, not just visually.
- **`SettingsGroup`** is the one exception: a labelled group of controls
  *inside* a screen (Appearance's "Theme" / "Accent colour"), not a list of
  navigable rows, so it renders as plain layout rather than an `mdui-list`.

See `docs/modules/settings.md` for the full registry contract these compose.

## 12. Icons

`material-symbols` (npm), self-hosted, all three silhouettes (Outlined,
Rounded, Sharp) as variable fonts — full Material Symbols set, no Google
Fonts CDN, works fully offline.

- **Always go through `src/components/Icon.tsx`.** Never use MDUI's
  `icon=`/`active-icon=` attributes (see §9) — they resolve against the
  legacy `'Material Icons'` font, which isn't loaded, and a document-level
  style can't repoint the font MDUI's `mdui-icon` uses inside its own shadow
  root anyway. `<Icon>` renders a plain `<span>` in light DOM instead, passed
  into an `icon` / `active-icon` slot:

  ```tsx
  <mdui-navigation-bar-item value="/">
    <Icon slot="icon" name="library_music" />
    <Icon slot="active-icon" name="library_music" filled />
    Library
  </mdui-navigation-bar-item>
  ```

- **Rounded is the default** variant, matching the Expressive direction in
  §1. Pass `variant="outlined" | "sharp"` to override per-icon.
- **Four runtime axes**, all props on `<Icon>`: `filled` (`FILL` 0/1),
  `weight` (`wght` 100–700), `grade` (`GRAD` -25–200), `size` (drives
  `opsz` 20–48 and `font-size`). Active nav/list items should set `filled` —
  see §11.1 CTA icons and the empty-state table above for outline defaults.
- **No `color` prop.** Icons render in `currentColor` — set color via a
  Tailwind class or MDUI color token on an ancestor, per §3.
- **Omit `size` inside MDUI slots** so the host component's own sizing
  (`font-size: inherit` for nav items, `1.5rem` for list items) wins.
- Icon names are typo-checked against the `MaterialSymbol` union the
  `material-symbols` package ships — no `_outlined`/`_rounded` suffix on the
  name itself, that's the `variant` prop and `FILL` axis.
- Only the Rounded font is precached by the service worker (`vite.config.ts`
  `workbox.globPatterns`); Outlined and Sharp cache on first use via a
  `CacheFirst` runtime rule, so all three still work offline once touched.
