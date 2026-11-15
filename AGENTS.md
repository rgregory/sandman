# Agents

Instructions for AI agents working on Sandman.

## Read first

- [DESIGN.md](DESIGN.md): visual and documentation rules. Follow it for any
  UI change and any change to `README.md` or `docs/`.

## Docs

- Diagrams follow the Diagram style in DESIGN.md; `docs/layered-sandboxes.svg`
  is the reference to match.
- No Markdown tables, anywhere. Draw comparisons as SVG diagrams instead
  (see DESIGN.md).
- Keep `README.md` short: overview, run, reading the list, one visual per big
  idea, links. Put detail in a deep dive under `docs/` and link it.
- When a feature changes, update its deep dive and, if the overview changes,
  the README. Check every SVG renders before committing.

## Code

- Swift Package, macOS 14+. Build with `./build.sh run`.
- Status colours from `Palette`; glyph views take `selected:` from the table.
- Commit messages: a short summary line, then what changed and why.
