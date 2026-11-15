# Design

How Artemis looks and how its docs read. Applies to the app and to everything
under `docs/`.

## Documentation

- **Show, don't tabulate.** No Markdown tables. When content compares things,
  draw it: a diagram, a legend, a before/after. Prose or a short list is fine
  for anything that isn't a comparison.
- **Visuals are SVG in `docs/`,** embedded with `<img src=... width="100%">`
  and a full `alt` text that says what the picture shows, so it still reads
  without the image.
- **Every SVG works in light and dark.** Use classes for colour and an
  `@media (prefers-color-scheme: dark)` block inside the SVG. Use the system
  font stack, no web fonts, no external references.
- **Use the app's own vocabulary and colours** in diagrams: green for App
  Sandbox, orange for open, indigo for an app's own sandboxes, blue for
  Artemis's seatbelt, red for blocked or risky.
- **Check the render.** Rasterise each SVG (for example `rsvg-convert`) and
  look at it before committing. No overlapping labels, no text past its box.
- **README is the overview, `docs/` is the depth.** README: what it is, how to
  run it, how to read the list, one visual per big idea, links to deep dives.
  Anything longer than a short paragraph goes in a deep dive, and the README
  links to it with "More →".
- **Plain words.** Short sentences, no marketing, no jargon without a
  one-line explanation.

## App

- Visual over textual: glyphs, meters and stacks in the list; words go on the
  second line or in the tooltip.
- Status colours come from `Palette` (adaptive, readable in light and dark),
  never raw system colours.
- Coloured content on a selected row turns white.
- Every theme in View › Theme must keep badges and status text readable.
