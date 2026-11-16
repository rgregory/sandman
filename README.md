# Sandman

A Mac app that shows which installed applications run without Apple's
[App Sandbox](https://developer.apple.com/documentation/security/app-sandbox),
ranks them by how exposed they are, and lets you put a seatbelt on the ones
you choose.

An app without a sandbox can read and change anything you can. Sandman shows
which apps those are, which of them face the outside world or take orders
from agents, and limits what a compromised one could do.

## Run it

macOS 14+ and Xcode 15+.

    ./build.sh run        # build and open
    ./build.sh install    # put it in /Applications

## Reading the list

Up top: how many apps are running unsupervised right now (no sandbox, no
seatbelt, and facing outside content or agents), as a ring and a sentence;
click it to list them. The list opens
on apps with no sandbox, riskiest first. The tiles split
the apps by what keeps them in check (No sandbox, Layered, Managed,
Sandboxed) and the bar shows the share with none at all; the ⚡ toolbar toggle narrows
everything to apps running right now.

<p align="center">
  <img src="docs/reading-the-list.svg" width="100%"
       alt="Legend. Exposure: a five-bar heat meter that fills and warms with risk, a down arrow for apps that pull in outside content, an up arrow for apps that take orders from an agent. Sandbox: green shield sandboxed, orange open lock none, indigo stack for apps whose helpers sandbox themselves, the same stack with a red warning triangle when their renderers run unsandboxed, blue half shield managed. Manage, signature and live: plus button to manage, green seal signed and hardened, amber ad hoc, red unsigned, pulsing orange dot running right now without a sandbox.">
</p>

Double-click a row for the details sidebar: what keeps the app in check,
what it pulls in or takes orders from, and what its entitlements actually
let it reach, in sentences rather than keys.
[More →](docs/how-it-works.md)

## Managed Applications

Managing an app writes a seatbelt profile for it and a launcher in
`~/Applications/Managed Applications`. Started that way, it can't touch your
credentials, mail and messages, login items or launch agents, and every
blocked attempt is logged. The app itself isn't modified.
[More →](docs/managed-applications.md)

## Layered sandboxes

"No sandbox" describes the main process only. Chromium, Firefox and Electron
apps lock each helper into its own sandbox, and sandboxes don't nest.
Electron apps whose windows run unsandboxed get a red ⚠ and rank higher.

<p align="center">
  <img src="docs/layered-sandboxes.svg" width="100%"
       alt="Three panels. App Sandbox: one green sandbox around the main process and all its helpers, set by the developer. Its own sandboxes: no App Sandbox on the main process, but each helper locked in its own indigo box, as in Chromium and Firefox. Sandman's seatbelt: one blue profile wrapped around the whole app from outside. Underneath: they don't nest; macOS refuses with forbidden-sandbox-reinit.">
</p>

Click the **Layered** tile to see it for a real app: each process, whether
it's sandboxed right now, and the IPC lines to the main process that brokers
for them.

<p align="center">
  <img src="docs/layered-view.png" width="100%"
       alt="Sandman with the Layered tile selected. At the top, a red ring reads 50 percent: 7 of 14 apps running unsupervised. Below, Claude's card: the main process on the left in dashed orange, 1 running, not sandboxed, joined by an IPC line to its helpers on the right. Renderers, GPU, Network service and Audio service are indigo and sandboxed; Utility services and the crash reporter are red, running without a sandbox.">
</p>

[More →](docs/layered-sandboxes.md)

## Deep dives

- [Managed Applications](docs/managed-applications.md): what's blocked, the options, Replace App, running unprotected
- [Layered sandboxes](docs/layered-sandboxes.md): helper sandboxes, the live check, managing a browser
- [Exposure](docs/exposure.md): how apps are rated
- [Logging](docs/logging.md): what's recorded and where
- [Privacy prompts](docs/privacy-prompts.md): why macOS may name Sandman
- [How it works](docs/how-it-works.md): and what it doesn't catch

Themes: View › Theme (Standard, Retro, OS 9, Copland, Things 3, Ink).
