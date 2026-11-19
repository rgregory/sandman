# Design

How Sandman looks and how its docs read. Applies to the app and to everything
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
  Sandman's seatbelt, red for blocked or risky.
- **Check the render.** Rasterise each SVG (for example `rsvg-convert`) and
  look at it before committing. No overlapping labels, no text past its box.
- **README is the overview, `docs/` is the depth.** README: what it is, how to
  run it, how to read the list, one visual per big idea, links to deep dives.
  Anything longer than a short paragraph goes in a deep dive, and the README
  links to it with "More →".
- **Plain words.** Short sentences, no marketing, no jargon without a
  one-line explanation.

## Diagram style

The reference is `docs/layered-sandboxes.svg`. Match it.

- **Flat and light, GitHub-docs feel.** White card, no gradients, no textures,
  no 3D. Soft rounded corners (10-16px), 1.2-3px strokes, generous whitespace.
- **Side-by-side panels** for anything compared (2-3 across). Each panel:
  bold title (17px, semibold), muted one-line subtitle (12px), the diagram,
  then a 3-4 line plain-language caption underneath (13px).
- **A container with a pill label on its border** names what each diagram is
  (`APP SANDBOX`, `SANDMAN SEATBELT`): small caps, 11px semibold, coloured
  outline, background-filled so it sits on the line.
- **Rounded tiles inside** for the parts (processes, helpers), labelled in
  plain words. Neutral grey outline unless the colour means something.
- **Colour carries meaning, and only meaning:** green = protected/safe,
  orange + dashed outline = open/unprotected, indigo = sandboxes itself,
  blue = Sandman's seatbelt, red = blocked/risky. Tinted fills are pale
  versions of the stroke colour.
- **One footer callout strip** for the takeaway: pale panel, a small
  pictogram on the left, a **bold lead-in sentence**, then one or two plain
  sentences. Code in monospace, coloured by meaning.
- **System font stack, 960px wide viewBox,** colours in classes with an
  `@media (prefers-color-scheme: dark)` block, full `alt` text where embedded.
- **No decoration that doesn't explain something.** If a shape doesn't help
  the reader understand, cut it.

## Layers

Three depths of one answer — not three audiences, and not a setting. Age and
"technical level" are the wrong axis: they are proxies for two things that pull
apart, whether someone has the vocabulary and whether they can act. What
actually varies is which of these three they need, and the same person needs
different ones on different days.

- **Verdict.** The top of the window. Does anything need doing, and what.
  Counts, never percentages. Consequences, never mechanisms. No term from this
  domain at all — not sandbox, not seatbelt, not exposure.
- **Reason.** The list. Why this app is here, said as what it can do to you,
  with one line of specifics under it.
- **Evidence.** The details sidebar and the deep dives. Entitlements,
  signatures, seatbelt profiles, log lines, the meters. Precise terms belong
  here, and only here.

Progressive disclosure carries it: the verdict is always on screen, the rows
are a glance below, the evidence is one click. Nothing is behind a preference.

The test for the verdict layer: read the top line down a phone line to someone
who has never heard of the App Sandbox, and they know whether to act.

## Vocabulary

- **Above the evidence layer, no word the reader has to be taught.** Unrestricted,
  not "no sandbox". Limits, not "seatbelt". What reaches it, not "exposure".
  "Managed" keeps its name — it is a feature with a deep dive of its own, and
  the row says what it means.
- **Say the consequence, not the mechanism.** "Can operate your other apps"
  beats "has AppleEvents entitlement". The entitlement goes in the sidebar.
- **No number without its unit in words.** A bare percentage is not a finding,
  and a denominator that changes when an app quits makes the number drop when
  nothing got safer.
- **Nothing is labelled with a judgement it can't support.** "Quiet" sounded
  like a verdict and was only an absence of signals.

## App

- Visual over textual: glyphs, meters and stacks in the list; words go on the
  second line or in the tooltip.
- Status colours come from `Palette` (adaptive, readable in light and dark),
  never raw system colours.
- Coloured content on a selected row turns white.
- Every theme in View › Theme must keep badges and status text readable.
