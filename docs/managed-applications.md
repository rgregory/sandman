# Managed Applications

A managed application is an unsandboxed app that Artemis has written a
sandbox (seatbelt) profile for and can start inside it. The app itself is not
modified.

To manage one, right-click it and choose Manage, or use the Manage button in
the details sidebar. A sheet shows what will always be blocked, the four
choices you can make, and how the protection applies. Confirming writes the
profile and creates a launcher in `~/Applications/Managed Applications`.

Started with its seatbelt, a managed application can't:

- read or change passwords and keys (`~/.ssh`, cloud and command-line
  credentials, other browsers' profiles, 1Password data)
- read Mail, Messages, Contacts or Calendar data
- write to login items, launch agents, shell startup files or other apps
- accept connections from other machines

Four checkboxes adjust this: incoming connections, all network access,
Documents, Desktop, Downloads and iCloud, and the Keychain. The Keychain is
left open by default, because blocking `~/Library/Keychains` makes browsers
and anything else that saves passwords report "Keychain Not Found".
Everything else works as before.
The app can still update itself, and a browser or password manager keeps
access to its own data.

Apps that ship with macOS can't be managed, and apps that are already
sandboxed don't need it.

Apps that sandbox themselves (Chromium, Firefox, Electron) are a special case:
see [Layered sandboxes](layered-sandboxes.md) before managing one.

## The Managed view

The Managed tile shows one card per managed app:

- its state: Protected now, Not running, or Running unprotected
- what it can't do, and what the current options leave unrestricted
- a live trace of CPU, disk reads, disk writes and blocked attempts over the
  last two minutes, while it is running with its seatbelt
- totals from the log: blocked attempts, runs without the seatbelt, and the
  last protected launch
- Launch Protected, Replace App and Options buttons

Right-click a card to reveal its launcher or to delete it from Managed
Applications. Deleting removes the profile and launcher, not the app.

## When a managed app is running unprotected

The seatbelt only applies when the app is started from Artemis or from its
launcher. Opened any other way, it runs with your full permissions.

Artemis makes that state obvious: the card gets a red banner and border, its
protections are struck through, and the Managed tile turns red with a count.
Quit & Relaunch Protected asks the app to quit and starts it again with its
seatbelt.

The state is read during a scan, so it updates on rescan or after a launch,
not the instant you open something from the Dock.

## Where things are kept

- Profiles: `~/Library/Application Support/Artemis/Profiles`
- Launchers: `~/Applications/Managed Applications`
- Logs: `~/Library/Application Support/Artemis/Logs`

A managed app can't write to any of these.

This relies on `sandbox-exec`, which Apple has marked deprecated but still
ships.

## Replace App

Replace App closes most of the gap left by launching an app the usual way. It
moves the real app to `~/Applications/Managed Applications/Originals` and
puts a launcher with the same name and icon where the app used to be, so the
Dock, Finder and Spotlight all start it with its seatbelt. Restore Original
App puts everything back, and so does removing the app from Managed
Applications.

What it does not cover: a file or link that opens in the app can still start
the real app directly. The app's own updater may complain that it has moved.
macOS may ask for permission before Artemis can move an app, and apps
installed by an administrator for all users may refuse to move.

---
[← Back to the README](../README.md)
