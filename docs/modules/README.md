# Module Docs

This directory holds one document per feature module that is large or
extensible enough to need its own reference, separate from the by-concern
docs one level up (`architecture.md`, `data-model.md`, `design-system.md`,
`ux-flows.md`). Most features don't need one — a row in `ux-flows.md` and
`features.md` is enough. Write one here when a module has its own extension
contract that future work needs to follow (a registry, a plugin shape, a
generated-screen pattern) — the kind of thing that's easy to drift from if
it only lives in code comments.

`docs/modules/settings.md` was the first; `docs/modules/capture.md` is the
second, covering the notation-capture render pipeline, draft reducer, and
tool-mode contract. Either is a fine template for the next.

## Conventions

Same as the rest of `docs/`: Title Case H1, numbered `## 1.` / `### 1.1`
headings (nothing past H3), tables over prose for mappings, inline status
columns rather than a separate roadmap, and cross-references written as
`` `docs/x.md` §N``. No table of contents block — the numbered headings are
the TOC.
