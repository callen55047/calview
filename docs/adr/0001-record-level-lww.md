# Record-level last-write-wins for calendar sync

Offline edits will merge by keeping the record with the newest `updatedAt` (device wall clock); we do not merge field-by-field or use logical/vector clocks. Chosen because a shared family calendar has a low, human-coordinated conflict rate, which makes last-write-wins' simplicity worth its cost: a concurrent edit to a *different field* of the same record is silently dropped (the whole losing record is discarded, not merged).

Every mutation stamps `updatedAt = Date()` now, even though the sync engine is deferred — the clock is painful to backfill onto records created before the field existed. Deletions are soft (an `isDeleted` tombstone) so they can propagate to other devices once sync lands.

Clock skew decides ties under this model. When sync ships we can blunt skew by clamping `updatedAt` to server time on push, without changing the data model.
