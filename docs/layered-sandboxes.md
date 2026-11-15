# Layered sandboxes

"Sandboxed" or "No sandbox" is a statement about one process: the app's main
executable. Many apps are really several processes, and the sandboxes can sit
in layers.

<p align="center">
  <img src="layered-sandboxes.svg" width="100%"
       alt="Three panels. App Sandbox: one green sandbox around the main process and all its helpers, set by the developer. Its own sandboxes: no App Sandbox on the main process, but each helper (Pages, GPU, Network, Utility) locked in its own indigo box, as in Chromium and Firefox. Artemis's seatbelt: one blue profile wrapped around the whole app from outside. Underneath: they don't nest; macOS refuses with forbidden-sandbox-reinit.">
</p>

All three are built on the same macOS mechanism (Seatbelt), and it doesn't
nest: a process that is already in a sandbox can't enter another one. macOS
refuses with `forbidden-sandbox-reinit`, which shows up in a managed app's
Activity log.

## Apps that sandbox themselves

Chromium and everything built on it (Chrome, Edge, Brave, Arc, Vivaldi, Opera,
Electron and CEF apps) and Firefox split into many processes and lock each
helper into its own profile as it starts:

- Renderers / web content: run web pages and their JavaScript. The strictest
  profile: no files, no network, no other apps.
- GPU: draws to the screen.
- Network service: fetches everything from the internet.
- Utility, storage, audio and media services: decode untrusted data.
- Plugins, where the app still has them.

A hostile page has to escape the renderer, then find a second bug in a more
trusted process, before it reaches your files. The weak spot is the main
process, which has no App Sandbox and runs with your full permissions. That is
why Artemis lists these apps among the unsandboxed ones, but doesn't treat
them as wide open.

Electron apps only get this if the developer leaves it on. Renderer
sandboxing is the default in current Electron, but the app's own code runs in
the main process with full access, and older or misconfigured apps switch the
renderer sandbox off.

## What Artemis shows

- The Sandbox column draws these apps as a fanned stack of indigo cards with
  the number of sandboxed process kinds it found, for example "4 sandboxes"
  for Chrome, and the layers underneath (Pages · GPU · Network · Plugins ·
  main open).
- The details sidebar has a Sandbox layers panel. While the app is running it
  asks the kernel about every process inside the bundle, groups them by role
  (from Chromium's `--type=` and `--utility-sub-type=` arguments, or Firefox's
  process type) and shows how many of each are sandboxed. When the app isn't
  running it reads the helpers from the bundle instead.
- The panel warns when renderers or web content run unsandboxed. That means
  the app was started with `--no-sandbox`, or its developer turned sandboxing
  off.
- Other apps that ship sandboxed XPC services or helpers (Sparkle's
  downloader, for example) show "N sandboxed helpers" and get the panel too.

## Managing a layered app

Because sandboxes don't nest, a seatbelt can only go on one of these apps if
its own sandboxes come off. Artemis detects them, warns in the Manage sheet,
and won't manage one until you tick "Turn off its own sandbox". It then starts
Chromium-based apps with `--no-sandbox` and Firefox with its sandbox
environment variables switched off.

<p align="center">
  <img src="managing-layered-app.svg" width="100%"
       alt="Left, keep its own sandboxes: a hostile page is trapped in the renderer's sandbox and needs two bugs to reach your files, but the main process has full user access and nothing is logged. Best for web browsers. Right, Artemis's seatbelt: the renderer has no box of its own, so the page reaches whatever files the seatbelt allows, but credentials are blocked, the main process is kept from credentials, mail and launch agents, and every blocked attempt is logged. Worth it when the renderers run unsandboxed anyway.">
</p>

For a web browser this is a bad trade and not recommended: the browser's own
sandbox contains a hostile page far better than one seatbelt around the whole
app. For an Electron app whose renderers turn out to be unsandboxed anyway,
the seatbelt can be the better of the two; check the Sandbox layers panel
first.

---
[← Back to the README](../README.md)
