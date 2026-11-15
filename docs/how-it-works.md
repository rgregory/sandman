# How it works

Every signed Mac app carries a list of entitlements. Sandman reads that list
for each app and looks for one entry: `com.apple.security.app-sandbox`. If it
is there and set to true, the app is sandboxed. It is the same thing you would
see from `codesign -d --entitlements - SomeApp.app`.

For apps that are open, Sandman also asks macOS whether the running process is
really in a sandbox. That is how it tells a managed app running with its
seatbelt from one running without it.

A managed app's profile allows everything by default and then denies a fixed
list of locations and operations. Its launcher is a small app that starts the
real one under `sandbox-exec` with that profile.

## What it doesn't catch

- It reads signatures but doesn't verify them, so it won't notice an app that
  has been tampered with.
- It only looks at apps. Command-line tools and background services aren't
  covered.
- Layer detection reads helper names and, while an app runs, its processes.
  An app that sandboxes itself in some other way still shows as "None".
- A seatbelt blocks files, not keychain items: an app can still use keychain
  entries it was already allowed to use.
- "Block all network access" does not stop DNS lookups, which go through a
  macOS service.

Sandman is not sandboxed itself. It couldn't inspect other apps if it were.

---
[← Back to the README](../README.md)
