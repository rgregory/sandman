# Exposure

Each app is given an exposure rating, and the list is sorted with the most
exposed first:

- Pulls: it takes in content it does not control, such as web pages,
  messages, downloads or links.
- Agent: it acts on instructions from an AI model, an agent, scripts or
  other automation.
- Pulls + agent: both, which is the highest risk for an app with no sandbox.

The rating comes from the app's declared link types, whether it is built on
a browser engine, whether it can control other apps, and a built-in list of
well-known browsers, chat apps, terminals, editors and AI tools. These are
signals, not proof, and the list is not complete. Hover over the rating, or
open the details sidebar, to see the reasons. The rating is included in the
CSV export.

---
[← Back to the README](../README.md)
