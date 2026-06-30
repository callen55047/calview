# 📅 calview

**A shared calendar built for life on shift work.**

calview puts everyone in your household on the same page — see each other's
events at a glance, know who's on a night shift, and capture plans in a couple
of taps. It's offline-first: every core action works on-device with no network,
no account, and no waiting.

> Inspired by partners coordinating around shift work — but built for any family,
> couple, or household that wants one calendar they actually share.

---

## ✨ What makes it different

### 🌙 Shift work, front and center
Mark a whole day as a **night shift** and it paints the calendar background, so
the whole household instantly sees who's working when — no squinting at event
titles. A Shift Day isn't an event; it's the rhythm your week is built around.

### 🎨 Shareable color legends
Every event belongs to a **Category** — Doctor, Gym, Work, Date Night — and each
Category carries a color. Edit the shared **Legend** once and every event
recolors everywhere. One glance tells you what kind of day it is.

### ⚡ Dead-simple event creation
Tap an empty slot, give it a title and a time, pick a color. Done. Editing and
deleting are just as quick. Creating a plan should be faster than texting about
it.

### 👥 Built for sharing
Every event is attributed to the **Member** who made it, so you always know who
added what — attribution that survives even before cloud accounts exist.

---

## 🧭 How it works

| Concept | What it means |
|---|---|
| **Member** | A person who shares the calendar — family, partner, or housemate. |
| **Event** | A single entry with a title, time range, and a Category. |
| **Category** | A named, color-coded kind of event. Supplies the color in the UI. |
| **Legend** | The full set of Categories — edit it to add, rename, or recolor. |
| **Shift Day** | A whole day marked as a night shift, drawn as a background overlay. |
| **Offline Mode** | On-device reads and writes only. The default, fully-built mode today. |

See **[CONTEXT.md](CONTEXT.md)** for the full domain language.

---

## 🛠 Built with

- **SwiftUI** — native iOS, month / week / day views
- **Offline-first storage** — everything works with no network
- **Firebase** — the shared cloud backend events sync toward

---

## 🚀 Getting started

```bash
open calview.xcodeproj          # then ⌘R in Xcode, or:

xcodebuild build -scheme calview \
  -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug
```

For the full build → run → screenshot verification loop and project gotchas,
see **[AGENTS.md](AGENTS.md)**. Architecture decisions live in
**[docs/adr/](docs/adr/)**.

---

## 🗺 Roadmap

calview is offline-first today, with a local-first **sync layer** on the horizon —
the same shared calendar, kept in step across every Member's device.
