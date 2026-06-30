# calview

A shared calendar for a small group of people — a family or household — to see each other's events in one place. Couples (e.g. partners coordinating around shift work) are one inspiring scenario, not the whole picture. The app is offline-first: every core action works on-device with no network, and changes are designed to sync to a shared cloud calendar later.

## Language

**Member**:
A person who shares the calendar (a family member, partner, or housemate). Events are attributed to the Member who authored them.
_Avoid_: user, account, owner.

**Local User Id**:
A stable opaque identifier generated on a device's first launch, standing in for a Member before cloud accounts exist. Stamped on every Event that device authors so attribution survives the first sync.
_Avoid_: deviceId (it identifies the person-on-this-install, not the hardware).

**Event**:
A single calendar entry with a title, a start and end time, and a Category. Authored by one Member.
_Avoid_: appointment, entry, item.

**Category**:
A named, color-coded kind of Event (e.g. Doctor, Gym, Work). A Member picks one Category per Event; the Category supplies the color shown in the UI.
_Avoid_: tag, type, label, color.

**Legend**:
The full set of Categories. Editing "the legend" means adding, renaming, recoloring, or removing Categories.
_Avoid_: palette, key.

**Shift Day**:
A whole day marked as a night shift (vs. a normal day), drawn as a background overlay on the calendar. Inspired by partners coordinating around shift work, but available to any Member.
_Avoid_: shift event (it is not an Event — it has no time range and no Category).

**Offline Mode**:
A *deliberate* startup setting under which the app reads and writes only on-device storage and never contacts the backend. The default and only fully-built mode in this iteration. Distinct from connectivity-driven degradation: a dropped network does **not** put the app into Offline Mode — that graceful behavior belongs to the future local-first sync layer, not to this setting.
_Avoid_: dev mode, local mode, test mode.

## Example dialogue

> **Dev:** When a Member marks a Shift Day, is that an Event?
> **Domain:** No. A Shift Day colors the whole day in the background — it has no time and no Category. An Event is a thing that happens at a time, like a Doctor visit.
> **Dev:** And the Category is where the color comes from?
> **Domain:** Right. Every Event points at one Category in the Legend, and the Legend says what color that is. Change the Category's color and every Event in it recolors.
> **Dev:** Before cloud accounts, how do we know which Member made an Event?
> **Domain:** Each install gets a Local User Id on first launch. We stamp it on everything that device creates, so when two people finally sync, we still know who authored what.
