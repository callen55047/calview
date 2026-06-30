# AGENTS.md — Working on calview

calview is a SwiftUI iOS app (offline-first shared calendar). This file captures
the **build → run → see-it-working** loop an agent should use to verify changes,
plus project-specific gotchas. For the domain language (Member, Event, Category,
Legend, Shift Day, Offline Mode) read [CONTEXT.md](CONTEXT.md); for architecture
decisions see [docs/adr/](docs/adr/).

## Project shape

- **Xcode project**: `calview.xcodeproj`, scheme `calview`, unit tests `calviewTests`.
- **Synchronized file groups**: the project uses `PBXFileSystemSynchronizedRootGroup`,
  so **new `.swift` files under `calview/` are picked up automatically** — never
  hand-edit `project.pbxproj` to register a file.
- **Source layout**: `Models/`, `Services/` (incl. `LocalCalendarService`,
  `LocalStore`), `Store/CalendarStore.swift` (`@Observable`), `Views/`, `Config/`,
  `Extensions/`.

## The verification loop

The whole point: don't just compile — **launch the app and look at it**. A change
isn't "done" until a screenshot (and, where it matters, a synthesized tap) proves
the behavior.

### 1. Build, install, launch

```bash
# Pick any booted iPhone simulator; boot one if needed:
xcrun simctl list devices booted
# open -a Simulator ; xcrun simctl boot "iPhone 17"   # if none booted

xcodebuild build -scheme calview \
  -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug 2>&1 \
  | grep -E "error:|BUILD"        # filter the firehose to errors + result

APP=~/Library/Developer/Xcode/DerivedData/calview-*/Build/Products/Debug-iphonesimulator/calview.app
xcrun simctl install booted $APP
xcrun simctl terminate booted com.egan.calview 2>/dev/null
xcrun simctl launch booted com.egan.calview
```

### 2. Screenshot

```bash
sleep 2   # let the UI settle / animations finish
xcrun simctl io booted screenshot /tmp/shot.png
```

Then read `/tmp/shot.png`. This alone verifies static layout.

### 3. Drive the UI with taps (verify interactions)

To exercise flows like *tap an empty grid slot → event-create sheet*, synthesize
clicks with the bundled helper. **Requires Accessibility permission** for the app
running the commands (System Settings → Privacy & Security → Accessibility).

```bash
swiftc scripts/simclick.swift -o /tmp/simclick   # one-time per session
```

**Map a screenshot point to a global click coordinate.** Get the Simulator
window's on-screen frame (re-fetch each session — the window can move):

```bash
osascript -e 'tell application "Simulator" to activate' -e 'delay 0.3' \
  -e 'tell application "System Events" to tell process "Simulator" \
      to get {position, size} of window 1'
# -> e.g. 180, 208, 456, 972   (winX, winY, winW, winH)
```

The window content maps the device screen **linearly**. Given a feature at
fraction `(fx, fy)` of the screenshot (fx = pixelX / imageW, fy = pixelY / imageH):

```
globalX = winX + fx * winW
globalY = winY + TITLEBAR + fy * (winH - TITLEBAR)      # TITLEBAR ≈ 28
```

If a tap lands slightly off, **calibrate from two known-good taps** (solve the
linear fit `globalY = a*fy + b`). On the geometry above this resolved to
`a ≈ 945, b ≈ 235` — close to the TITLEBAR≈28 model. Example taps that worked:

```bash
osascript -e 'tell application "Simulator" to activate' >/dev/null; sleep 0.3
/tmp/simclick 408 387    # the "Week" segmented-control tab
/tmp/simclick 324 683    # an empty ~11 AM slot in a week column -> create sheet
```

**Notes / gotchas for taps:**
- `osascript … "click at {x,y}"` does **not** work here (fails with -25204). Use
  the `simclick` CGEvent helper instead.
- Large hit targets (rows, grid cells, segmented tabs) are reliable. Very small
  top-nav buttons (a "Cancel" capsule right under the status bar) can be missed
  by a few px — retry, nudge Y, or reset state with terminate+launch instead.
- Re-`activate` the Simulator before a tap so it's frontmost.

### 4. Run unit tests

```bash
xcodebuild test -scheme calview \
  -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:calviewTests 2>&1 \
  | tail -25
```

## Gotchas worth remembering

- **SourceKit in-editor diagnostics lie across files.** While editing you'll see
  swarms of `Cannot find 'CalendarStore' / type 'CalEvent' in scope` — these are a
  stale single-file index, not real errors (they appear even in untouched files).
  **Trust `xcodebuild`, not the live diagnostics.**
- **Data only loads via `loadMonth()`.** `CalendarStore.loadMonth()` is triggered
  by `.task(id: store.displayedMonth)`. MonthView, WeekView, and DayView each
  carry that modifier so any of them can be the entry point and still show events;
  navigating within the same month does not reload (id unchanged).
- **`Color.clear` / `Rectangle` are greedy in unconstrained axes.** A
  `Color.clear.frame(width:)` spacer stays *vertically greedy* and will fight a
  sibling greedy `GeometryReader` for height (this caused a phantom blank band at
  the top of the week grid). Constrain both axes, or `.fixedSize(vertical: true)`
  the row.
- **Don't stack many tall columns side-by-side in a scroll.** Prefer one grid
  container with content positioned by offset (see `TimelineGridView`) over N
  full-height columns in an `HStack` — the latter destabilized vertical scroll.

## Calendar timeline (Week/Day views)

`Views/TimelineGrid.swift` holds the shared hour-timeline: `TimelineLayout`
(layout math + overlap column packing), `HourAxis`, `HourGridLines`, and
`TimelineGridView` (one grid for both views — `days: [Date]` is 1 for Day, 7 for
Week). Events are positioned by start/end time; tapping an empty slot calls back
with the tapped day+hour, opening `EventDetailView(defaultStart:)`. Both views
auto-scroll to the morning on open.
