# CLAUDE.md

See **[AGENTS.md](AGENTS.md)** for the build → run → screenshot → tap verification
loop, the iOS Simulator UI-automation recipe (`scripts/simclick.swift` +
coordinate mapping), and project-specific gotchas (SourceKit cross-file false
errors, `loadMonth()` data loading, greedy-SwiftUI layout traps).

Also relevant:
- **[CONTEXT.md](CONTEXT.md)** — domain language (Member, Event, Category, Legend,
  Shift Day, Offline Mode). Use these terms; honor the _Avoid_ lists.
- **[docs/adr/](docs/adr/)** — architecture decisions (e.g. record-level
  last-write-wins).

Always verify UI changes by actually launching the app in the simulator and
looking at a screenshot — compiling is not enough.
