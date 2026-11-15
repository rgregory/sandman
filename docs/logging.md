# Logging

While Sandman is open it records what each managed application does:

- when it was added, changed, replaced, restored or removed
- each launch with its seatbelt, from Sandman or from its launcher
- when a launch started from Sandman ended, how long it ran and its exit code
- each time it was opened without its seatbelt
- each attempt the seatbelt blocked: the process, what it tried, and the path
  or address, grouped into the same categories the profile uses

Each managed app's card shows the totals. The details sidebar has the recent
events and an Export Log button. Everything is appended to
`~/Library/Application Support/Sandman/Logs/events.jsonl`, one JSON object
per line.

Limits:

- Nothing is recorded while Sandman is closed.
- Blocked attempts are read from the macOS system log, which needs an
  administrator account. If that fails, the Activity box says so.
- macOS drops repeated denials, and Sandman keeps at most one identical
  blocked attempt every five seconds, so the counts are a minimum.
- The live trace covers the app's main process, not helpers it starts, and
  has no network channel.

---
[← Back to the README](../README.md)
