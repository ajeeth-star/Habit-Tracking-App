# Habit App — Design Spec

> **Naming:** on screen, each habit is called a **streak** (the Streaks tab, "New streak"). In code and in this spec, "task" and "habit" still mean the same thing.

The visual reference for every screen in v1. Read together with `docs/context.md`, which holds the product rules. If the two conflict on **behavior**, `context.md` wins. If they conflict on **looks**, this file wins. Anything marked **(open)** is undecided: build the default described here, and flag it to the owner instead of inventing something new.

The overall feel is calm, clean, and quietly encouraging. It should never feel punishing. The app uses one accent color for app-wide controls, a color per streak, lots of breathing room, no shadows, gradients only in three places (section 1.5), and no decoration that doesn't carry meaning.

---

## 1. Design system

All values live in a `DesignSystem/` folder and are used everywhere through these names. **Never hard-code a color, font, spacing value, or corner radius inside a view.**

### 1.1 Colors

Define each color as a Color Set in `Resources/Assets.xcassets/Colors/` with **Light and Dark variants**, then expose them as `Color.app.<name>` (e.g. `Color.app.accent`) in `DesignSystem/AppColors.swift`. The app must look right in both light and dark mode.

| Name | Light | Dark | Used for |
|---|---|---|---|
| `background` | `#F5F5F7` | `#0B0B0D` | Screen background behind everything |
| `surface` | `#FFFFFF` | `#1A1A1E` | Task cards, dialog, form fields |
| `surfaceMuted` | `#EEEEF2` | `#26262B` | Stat tiles, neutral pills, photo placeholders |
| `separator` | `#E3E3E8` | `#2E2E34` | Card outlines, dividers, unselected chip borders |
| `textPrimary` | `#141416` | `#F4F4F6` | Titles, task names, main text |
| `textSecondary` | `#5F5F68` | `#A3A3AD` | Meta lines, helper text, descriptions |
| `textTertiary` | `#8D8D96` | `#6E6E78` | Section headers, captions, "not today" names |
| `accent` | `#5A4FF3` | `#5A4FF3` | Filled buttons, selected day chips, the open-task outline |
| `accentText` | `#5A4FF3` | `#A39DFF` | Accent-colored **text and icons** (links, +, "Edit", "Cancel") |
| `accentSoft` | `#EEEDFE` | `#25224D` | "Open now" pill background |
| `onAccent` | `#FFFFFF` | `#FFFFFF` | Text and icons on top of `accent` |
| `success` | `#1A7F46` | `#4ADE80` | "Done" text and checkmarks |
| `successSoft` | `#E6F4EC` | `#13301F` | "Done" pill and done-day circle background |
| `danger` | `#C62828` | `#FF6B60` | "Streak ended" text, "Use skip" text, missed-day mark |
| `dangerSoft` | `#FDECEA` | `#3A1614` | "Missed" pill and missed-day circle background |
| `streak` | `#E8590C` | `#FF8A3D` | **The flame icon only.** Never used for text |
| `scrim` | black at 40% | black at 55% | Dim layer behind the skip dialog |

Rules:

- `accent` is the only "loud" color. Use it for the one most important action on a screen and nothing else.
- Never rely on color alone to carry meaning. Every status color is paired with text or an icon (e.g. a checkmark plus "Done").
- The camera and photo-preview screens are always black with white controls, in both modes.
- Text on the hero card's secondary line uses `onAccent` at 85% opacity, exposed as `Color.app.onAccentMuted` (derived from `onAccent`, not a separate color set).


### 1.1b Streak colors — `DesignSystem/StreakPalette.swift`

Each streak has one of 8 colors. They are color sets in `Resources/Assets.xcassets/Colors/Streak/` with light and dark variants, plus a **soft** set of each at 14% opacity for backgrounds. Expose them as `StreakColor.<name>` with `.main` and `.soft`, plus `.solid` (the light-mode main in both modes, for fills that carry white text or icons, so white stays readable in dark mode) and `.deep` (`.solid` 20% darker, the end of the hero gradient).

| Name | Light | Dark |
|---|---|---|
| `coral` | `#F2545B` | `#FF6B72` |
| `orange` | `#E8590C` | `#FF922B` |
| `green` | `#2B9348` | `#51CF66` |
| `teal` | `#0B9A8D` | `#38D9C3` |
| `blue` | `#1C7ED6` | `#4DABF7` |
| `indigo` | `#5A4FF3` | `#A39DFF` |
| `pink` | `#D6336C` | `#F783AC` |
| `purple` | `#9C36B5` | `#DA77F2` |

Rules:

- A streak's color marks **that streak** (its icon badge, its done days, its History chip, its hero card, its celebration glow). The app's `accent` stays the brand color for everything app-wide: the tab bar, the gear, +, the History link, the week strip, and primary buttons outside a specific streak.
- The `flame.fill` streak icon keeps the `streak` color everywhere.

**Streak icons** (SF Symbols, all available on iOS 17): `dumbbell.fill`, `figure.run`, `figure.walk`, `bicycle`, `drop.fill`, `sparkles`, `book.fill`, `pencil`, `brain.head.profile`, `guitars.fill`, `music.note`, `paintbrush.fill`, `fork.knife`, `cup.and.saucer.fill`, `leaf.fill`, `bed.double.fill`, `moon.fill`, `sun.max.fill`, `heart.fill`, `cross.case.fill`, `house.fill`, `cart.fill`, `laptopcomputer`, `star.fill`.

**Defaults for a new streak:** the first color (in the table's order) not used by an active streak (back to `coral` if all are taken), and an icon guessed from the name, case-insensitive: gym / lift → `dumbbell.fill`; run → `figure.run`; skin / face → `drop.fill`; read → `book.fill`; guitar → `guitars.fill`; dishes / clean → `sparkles`; sleep → `bed.double.fill`; otherwise `star.fill`. The guess follows the name as it's typed until an icon is picked by hand.

### 1.2 Typography

Use the system font through **Dynamic Type text styles**, so text scales with the user's iPhone text-size setting. Expose these as `Font.app.<name>` in `DesignSystem/AppFonts.swift`. Put `.monospacedDigit()` on any number that changes (streaks, counts, times) so digits don't jitter.

**Two designs of the system font:** **SF Pro Rounded** (`.rounded` design) for screen titles, card titles, and all numbers (streaks, counts, the progress ring). **SF Pro** (regular design) for meta lines, helper text, body text, and buttons. Which design each style uses is decided in `AppFonts` only.

| Name | Text style + weight | Design | Approx. size | Used for |
|---|---|---|---|---|
| `screenTitle` | `.title`, bold | Rounded | 28 | "Today", task name on the task screen |
| `successTitle` | `.title2`, bold | Rounded | 22 | "Gym done" |
| `emptyTitle` | `.title3`, semibold | Rounded | 20 | "Start your first streak" |
| `statValue` | `.title3`, semibold, monospaced digits | Rounded | 20 | "3w 2d", "1 of 1", the streak on the hero card |
| `cardTitle` | `.headline` (semibold) | Rounded | 17 | Task name on a card, dialog title, form screen title |
| `cardStreak` | `.headline` (semibold), monospaced digits | Rounded | 17 | The streak on the right of a (non-hero) task card |
| `statusCount` | `.subheadline`, semibold, monospaced digits | Rounded | 15 | The "2 of 3" count in Today's status line |
| `celebrationNumber` | bold, monospaced digits, fixed size | Rounded | 64 | The big streak number on the celebration |
| `celebrationIcon` | fixed size | — | 96 | The big flame on the celebration |
| `button` | `.body`, semibold | Regular | 17 | All button labels |
| `body` | `.body`, regular | Regular | 17 | Form field text |
| `subhead` | `.subheadline`, regular | Regular | 15 | Date line, dialog body, empty-state body, "day streak" |
| `meta` | `.footnote`, regular | Regular | 13 | Card meta line, helper text, schedule line |
| `sectionHeader` | `.footnote`, semibold | Regular | 13 | "Today", "Not today", "This week", "Recent check-ins" |
| `pill` | `.caption`, semibold | Regular | 12 | Status pills |
| `caption` | `.caption`, regular | Regular | 12 | Stat tile labels, field labels, day labels under circles, photo dates |
| `badgeIcon` | `.body`, semibold | — | 17 | The icon inside an `IconBadge` |
| `weekStripNumber` | `.subheadline`, semibold, monospaced digits | Rounded | 15 | Date numbers in the week strip |
| `tabIcon` | fixed size | — | 22 | Side tab icons |

`celebrationNumber` and `celebrationIcon` are fixed sizes: they're decorative and already very large. The text around them still scales.

Section headers are sentence case ("Not today"), not ALL CAPS.

### 1.3 Spacing

The app uses a 4-point grid. Expose this as `Spacing.<name>` in `DesignSystem/Spacing.swift`.

| Name | Value |
|---|---|
| `xxs` | 4 |
| `xs` | 8 |
| `sm` | 12 |
| `md` | 16 |
| `lg` | 20 |
| `xl` | 24 |
| `xxl` | 32 |
| `xxxl` | 40 |

Standard uses:

- Screen side padding: `lg` (20)
- Padding inside a card: `md` (16)
- Gap between cards: `sm` (12)
- Section header: `xl` (24) above, `xs` (8) below
- Gap between a card's title row and its meta line: `xxs` (4)
- Gap between a meta line and a button inside a card: `sm` (12)
- Gap between side-by-side buttons: `xs` (8)
- Gap between form sections: `xl` (24); field label to field: `xs` (8)

### 1.4 Corner radius

Expose this as `Radius.<name>` in `DesignSystem/Radius.swift`. Use continuous corners (`.continuous`) everywhere.

| Name | Value | Used for |
|---|---|---|
| `sm` | 8 | Photo thumbnails |
| `md` | 12 | Buttons, form fields, stat tiles |
| `lg` | 16 | Task cards |
| `xl` | 20 | Skip dialog |
| `full` | capsule / circle | Pills, day chips, day circles, the empty-state + |

### 1.5 Sizes, lines, and icons

- **Buttons:** 50pt tall, full width of their container unless side by side.
- **Tap targets:** at least 44×44pt everywhere, including icon-only buttons like + and Back.
- **Card outline:** a 0.5pt `separator` stroke. The hero card (open task) has no outline; its gradient fill sets it apart.
- **Celebration:** 96pt flame, 64pt streak number.
- **Shadows:** none.
- **Gradients:** allowed **only** on the hero card (its streak's `solid` → `deep`, top-left to bottom-right) and the celebration screen (a soft radial glow). Nowhere else.
- **Icon badge:** 40pt square, `Radius.md`, the streak's `soft` fill, its icon in the streak's `main`.
- **Tab bar:** 64pt tall plus the bottom safe area.
- **Week strip:** 36pt day circles, 3pt progress rings.
- **Icons:** SF Symbols only, sized to match the text next to them.
  - `plus` (create task, empty state)
  - `camera.fill` (Check in)
  - `flame.fill` (streaks, in `streak` color; `onAccent` on the hero card)
  - `checkmark` (done)
  - `xmark` (missed, close camera)
  - `minus` (skipped day)
  - `chevron.left` (back)
  - `camera.rotate` (flip camera)
  - `photo` (placeholder thumbnail)
  - `sun.max.fill`, `flame.fill` (tab bar), `gearshape` (Settings button), `chevron.right` (History link)
  - `moon.fill` (rest day), `checkmark` in `success` (all done) on the status line
  - The streak icons in section 1.1b
  - `chevron.down` / `chevron.up` (collapsible "Done today" and "Archived" rows), `chevron.right` (rows that open a screen)
  - `exclamationmark.triangle.fill` (notifications-off warning)

### 1.6 Motion and haptics

- Keep motion subtle and quick: system default animations, about 0.25s.
- **Streak celebration:** the flame scales from 0.5 to 1.0 with a spring, a **success haptic** plays, and the streak number counts up from the previous value. It closes on its own after **2.5 seconds** (tap anywhere to close sooner).
- **Week strip, today:** its progress ring animates to the new amount when a check-in completes.
- **Closing a task:** back on Today after a check-in, the hero card animates away and into the "Done today" row.
- **Confirming "Use skip":** a **warning haptic** plays.
- **Celebration glow:** fades and grows in behind the flame with the pop.
- **Settings → Vibrations** off turns off every haptic in the app.
- **Settings → Celebration animation** off shows the celebration's flame and number straight away, with no pop and no count-up (like Reduce Motion). It still closes on its own.
- Respect the Reduce Motion setting: when it's on, skip the pop, the count-up, the ring animation, and the card animation, and just show the end state. The glow is simply there. The celebration still closes on its own.

---

## 2. Reusable components

Put each in its own file under `Views/Components/`, with these exact names:

- **`PrimaryButton`**
  - 50pt tall, `accent` fill, `onAccent` label in `Font.app.button`, `Radius.md`, optional leading SF Symbol.
  - Disabled: `surfaceMuted` fill, `textTertiary` label.
  - **Inverted** variant (only on the hero card): `onAccent` fill (white in both modes), `accent` label.
- **`SecondaryButton`**
  - Same size, `surface` fill, 0.5pt `separator` stroke, `textPrimary` label.
  - Disabled: `textTertiary` label.
- **`DangerTextButton`**
  - Same size, `surface` fill, 0.5pt `separator` stroke, `danger` label.
  - Used only for "Use skip".
- **`StatusPill`**
  - Capsule, `Font.app.pill`, horizontal padding 8, vertical 3. Variants:
    - `open`: `accentSoft` / `accentText`, "Open now"
    - `done`: `successSoft` / `success`, checkmark + "Done"
    - `upcoming`: `surfaceMuted` / `textSecondary`, "Opens 9:00 PM"
    - `skipped`: `surfaceMuted` / `textSecondary`, "Skipped"
    - `missed`: `dangerSoft` / `danger`, "Missed"
- **`StreakLabel`**
  - Flame icon (`streak` color) followed by the formatted streak (section 3).
  - Has a `short` style ("3w 2d") and a `long` style ("3 weeks 2 days").
- **`TaskCard`**
  - The home-screen card, including the hero (open) card. Every state is described in section 4.1.
- **`StatTile`**
  - `surfaceMuted` fill, `Radius.md`, padding `sm` (12).
  - Label in `Font.app.caption` / `textSecondary`, with the value below it in `Font.app.statValue` / `textPrimary`.
- **`WeekDayCircle`**
  - 32pt circle with a weekday label below it ("Mon") in `Font.app.caption` / `textSecondary`, 4pt gap. States:
    - `done`: the streak's `solid` fill, `onAccent` (white) checkmark
    - `skipped`: `surfaceMuted` fill, `textSecondary` minus
    - `missed`: `dangerSoft` fill, `danger` xmark
    - `today`: no fill, 1.5pt `accent` ring, 6pt `accent` dot in the center
    - `upcoming`: no fill, 0.5pt `separator` ring
- **`DayChip`**
  - 36pt circle with a single letter in `Font.app.subhead`.
  - Selected: `accent` fill, `onAccent` letter. Unselected: no fill, 0.5pt `separator` stroke, `textSecondary` letter.
  - The VoiceOver label is the full day name ("Tuesday"), since T and S repeat.
- **`PhotoThumbnail`**
  - Square, `Radius.sm`, image fills it (cropped).
  - Placeholder: `surfaceMuted` with a centered `photo` icon in `textTertiary`.
- **`EmptyStateView`**
  - The first-launch view (section 4.2).
- **`FilterChip`**
  - Capsule with a label in `Font.app.subhead`, horizontal padding `sm`, vertical padding `xs`, 44pt tap target.
  - Selected: `accent` fill, `onAccent` label. Unselected: `surface` fill, 0.5pt `separator` stroke, `textPrimary` label.
- **`DisclosureRow`**
  - A collapsible row: label in `meta` / `textSecondary` (e.g. "Done today · 2", "Archived · 1"), `chevron.down` / `chevron.up` on the right, 44pt tall. VoiceOver reads it as a button with "expanded" / "collapsed".
- **`HabitRow`**
  - The Streaks tab card (section 4.10).
- **`AppDialog`**
  - The centered confirmation dialog over a `scrim` (layout as in section 4.5): title, body, then two stacked buttons. The **first, highlighted button is always the safe choice** ("Cancel", "Keep my skip") as a `PrimaryButton`; the second is the action, as a `SecondaryButton` (neutral) or `DangerTextButton` (destructive). Tapping the scrim counts as the safe choice. Used by the skip confirmation and every confirmation in sections 4.3, 4.11, and 4.13.
- **`PhotoViewer`**
  - One check-in photo full screen on black, its date and time at the top, and an `xmark` close button. Used by both History screens.
- **`IconBadge`**
  - 40pt square, `Radius.md`: the streak's `soft` fill with its icon in the streak's `main`, in `Font.app.badgeIcon`.
  - **On the hero card:** `onAccent` at 20% (`Color.app.onAccentFaint`) with the icon in `onAccent`.
  - Decorative: VoiceOver skips it (the name next to it says what it is).
- **`AppTabBar`**
  - The custom two-tab bar (section 4.0).
- **`WeekStrip`**
  - The Monday–Sunday strip on Today (section 4.1). Past days are tappable.
- **`StreakStylePicker`**
  - The "Color and icon" section of the form (section 4.3): a row of 8 color swatches and a 6-column icon grid.

---

## 3. Text formatting rules

Put all of these in `DesignSystem/Formatters.swift`. Write unit tests for the streak and count formats.

**Streak, long style:**

| Situation | Text |
|---|---|
| 3 weeks, 2 days | "3 weeks 2 days" |
| 1 week, 1 day | "1 week 1 day" |
| 0 weeks, 2 days | "2 days" |
| 3 weeks, 0 days | "3 weeks" |
| 0 and 0 | "No streak yet" |

**Streak, short style:** "3w 2d", "1w 1d", "2d", "3w", and "—" for zero.

**Streak, days-only mode** (the owner's toggle): "14 days", "1 day", and "No streak yet" for zero.

**Skips:** "1 skip left", "2 skips left", "No skips left".

**Times:** use the user's locale with a short time style (e.g. "6:00 PM").

**Time windows:** use Apple's `DateIntervalFormatter` with short time style, e.g. "6:00 – 8:00 PM".

**Next scheduled day:** "Tomorrow" if it's tomorrow, otherwise the weekday name ("Friday").

**Schedule summary:** short weekday names joined by commas, then " · ", then the window, e.g. "Mon, Tue, Thu, Fri · 6:00 – 8:00 PM". Every day reads "Every day"; Mon–Fri reads "Weekdays".

**Meta separator:** " · " (space, middle dot, space).

**Closes in** (hero card countdown, rounded up to the next whole minute): "Closes in 1h 20m"; whole hours drop the minutes ("Closes in 2h"); under an hour it's minutes only ("Closes in 12m", "Closes in 1m").

**Status line** (Today, under the week strip): "{count} done today · {next}", where the count is "2 of 3". Every streak scheduled today checked in: "All done for today · {next}". None scheduled today: "Rest day · {next}". With nothing coming up at all, just the first half.

**Next** (the status line's second half), in this order:
- A streak open right now (not checked in or skipped): "Gym is open now" (only while some are still to do, so never on "All done" or "Rest day")
- Later today: "Next: Journal at 9:00 PM"
- Tomorrow: "Next: Guitar tomorrow at 9:00 PM"
- Later this week: "Next: Walk Sunday at 10:00 AM"

**Streak celebration number:** the streak in days, as a plain number ("23"), with "day streak" under it.

**Coming up:** the next window's day and start time: "Tomorrow, 9:00 PM", otherwise the weekday name: "Sunday, 10:00 AM".

**History day headers:** "Today", "Yesterday", otherwise weekday, short month, and day: "Thursday, Sep 24".

**Best streak:** "Best: 5w 1d" (short style, or days-only following the setting; "Best: —" if there's never been a streak).

**Collapsible rows:** "Done today · 2", "Archived · 1".

**Photo storage:** "{n} photos · {size}" with the size from Apple's file-size formatter ("38 MB"); "1 photo"; "No photos" when there are none.

**Version:** "{version} ({build})", e.g. "0.1.0 (1)".

**Greeting:** "Good morning" from 5:00 AM, "Good afternoon" from noon, "Good evening" from 5:00 PM until 5:00 AM; with a name set, ", {name}" follows ("Good evening, Ajeeth"). The name is trimmed of leading and trailing spaces; an empty name means no name.

---

## 4. Screens

Put screens in `Views/<Area>/` with these exact names. Every screen uses `Color.app.background` behind its content and side padding of `Spacing.lg`.

### 4.0 Tab bar — `App/MainTabView.swift`, `Views/Components/AppTabBar.swift`

A custom tab bar with two tabs, left to right:

1. **Today** — `sun.max.fill`, label "Today" — section 4.1
2. **Streaks** — `flame.fill`, label "Streaks" — section 4.10

The app always opens on **Today**. Each tab has its own navigation stack, so going back never jumps to another tab, and switching tabs keeps each tab where it was. Tapping a reminder notification switches to Today. Screens presented full screen (camera, celebration, dialogs) and sheets cover the tab bar. **The tab bar hides while History is open** (section 4.12) and slides back when you return to Today.

**Look:**

- `surface` background reaching into the bottom safe area, a 0.5pt `separator` line along the top, 64pt tall plus the safe area.
- **Each tab:** a 22pt icon (`Font.app.tabIcon`) with its label in `caption` underneath. Selected: `accentText`. Unselected: `textTertiary`. Each half of the bar is its tab's tap target.
- VoiceOver reads them as tabs, with the current one marked selected.

**Planned, not built:** a third **Friends** tab comes with shared folders. Then Today moves to the center as a raised round button. Nothing for it exists in this version.

### 4.1 Today tab — `Views/Home/HomeView.swift`

Top to bottom: header → "This week" row → week strip → status line → hero card(s) → Today → Coming up. On a rest day there's no hero card and no Today section.
**Header** (scrolls with the content, no navigation bar title):

- Top row: a **gear** button on the left (`gearshape`, `textSecondary`, 44pt tap target, VoiceOver "Settings") opens Settings as a sheet (section 4.13). A **+** button on the right (`plus`, `accentText`, 44pt) opens Create Task.
- Below it, stacked: the greeting in `subhead` / `textSecondary` — "Good morning" (5:00 AM to before noon), "Good afternoon" (noon to before 5:00 PM), "Good evening" (5:00 PM to before 5:00 AM), followed by ", {name}" when a name is set in Settings ("Good evening, Ajeeth"); then "Today" in `screenTitle`; then the date in `subhead` / `textSecondary`, e.g. "Thursday, October 1".

**"This week" row**, `Spacing.md` below the date: "This week" in `sectionHeader` / `textTertiary` on the left; on the right, **"History"** and a `chevron.right` in `meta` / `accentText`, with a 44pt tap target. Tapping it opens History (section 4.12).

**Week strip** (`WeekStrip`), directly below that row:

- Seven equal columns, Monday to Sunday of the current week. Each column: the weekday letter in `caption` / `textTertiary`, `Spacing.xxs` above a 36pt circle with the date number in `Font.app.weekStripNumber` (rounded semibold, monospaced digits).
- Progress for a day = streaks checked in that day ÷ streaks scheduled that day (archived streaks left out; skips and misses don't count as done).
- **Past days with something scheduled:** a 3pt ring around the circle, `accent` on a `surfaceMuted` track, filled to that day's progress; number in `textPrimary`. **Fully done:** a filled `accent` circle with the number in `onAccent`.
- **Today:** a 1.5pt `accent` ring on the circle, number in `accentText`, and its 3pt progress ring around it (filled `accent` circle once everything is done). When a check-in completes, the ring animates to the new amount (not with Reduce Motion). This is the screen's progress indicator.
- **Future days, and days with nothing scheduled:** the plain number in `textTertiary`, no ring.
- **Tapping a past day** (with or without anything scheduled) opens History scrolled to that day (section 4.12). Today and future days do nothing when tapped.
- VoiceOver: past days read "Tuesday, 2 of 3 done. Opens history." ("Monday, all done. Opens history.", "Wednesday, nothing scheduled. Opens history."), with the button trait. Today reads "Thursday, today, 1 of 5 done"; future days just "Saturday".

**Status line**, `Spacing.sm` below the week strip: one line (wrapping if needed) in `subhead` / `textSecondary`.

- **In progress:** "2 of 3 done today · Next: Gym at 6:00 PM" — the count ("2 of 3") in `Font.app.statusCount` (rounded semibold) / `textPrimary`. If a streak's window is **open right now** (and it isn't checked in or skipped), the second half names it instead: "2 of 3 done today · Gym is open now". Otherwise the next streak later today, then tomorrow ("Next: Guitar tomorrow at 9:00 PM"), then later this week ("Next: Walk Sunday at 10:00 AM"). Text rules in section 3.
- **All done** (every streak scheduled today is checked in): a small `checkmark` in `success` at the start, then "All done for today · Next: Guitar tomorrow at 9:00 PM".
- **Rest day** (streaks exist, none scheduled today): a `moon.fill` in `textTertiary` at the start, then "Rest day · Next: Gym tomorrow at 6:00 PM" or "Rest day · Next: Gym Friday at 6:00 PM".
- If nothing at all is coming up, the part after " · " is left off.
- VoiceOver reads the line as one sentence.

**Hero card(s)**, `Spacing.md` below the status line: every streak whose window is open right now (and isn't checked in or skipped), in window order. This is the visual focus of the screen. Look: see "Hero card" below.

**Body:** two sections below the hero card(s), each headed with `sectionHeader` / `textTertiary` (`Spacing.xl` above, `Spacing.xs` below).

- **"Today":** the other tasks still ahead today (window opens later) — **sorted by window start time**. Open tasks aren't repeated here; they're the hero cards above. Hidden on a rest day, and when it would have no cards and no "Done today" row. A task that was **missed** today also stays here in its time-sorted spot, so its "Streak ended" lines stay visible.
- **"Done today" row**, at the bottom of the Today section: tasks **checked in or skipped** today collapse into one row, "Done today · 2" in `meta` / `textSecondary`, with a `chevron.down` (collapsed) or `chevron.up` (expanded) on the right. Tapping it shows or hides their compact cards (done and skipped states below), in window order. It starts collapsed; whether it's open is remembered until the app closes. Hidden when nothing is done or skipped. If nothing is ahead or missed either, the Today section shows only this row.
- **"Coming up":** one row per task **not scheduled today**, sorted by its next window (soonest first). Hide this section if it's empty. Each row: `surface` fill, `Radius.lg`, `Spacing.md` padding, 0.5pt `separator` outline; the streak's `IconBadge`, then its name in `cardTitle` / `textPrimary` on the left; the next window's day and start time on the right in `meta` / `textSecondary` ("Tomorrow, 9:00 PM", "Sunday, 10:00 AM"). VoiceOver reads "Guitar · Tomorrow, 9:00 PM". Tapping it opens the task screen.

Cards and rows are separated by `Spacing.sm`. **Tapping anywhere on a card** (other than its button) opens that task's screen.

**Hero card** (the open task: window open, not checked in or skipped):

- Fill: a gradient of the streak's color, `solid` to `deep`, top-left to bottom-right. `Radius.lg`, `Spacing.md` padding, no outline. All text and icons on it are `onAccent` (white).
- Title row: the `IconBadge` in its hero style on the left, `Spacing.sm` before the task name (`cardTitle`); on the right, the `flame.fill` icon and the streak (`statValue`), both `onAccent`. The streak follows Settings → Show streaks as.
- `xxs` below: "Closes in 1h 20m · 1 skip left" in `meta` / `onAccentMuted`. The countdown updates every minute; under an hour it reads "Closes in 12m".
- `Spacing.sm` below: a full-width **inverted** `PrimaryButton` "Check in" with `camera.fill`: `onAccent` (white) fill, label and icon in the streak's `solid` color. **No skip button here.**

**Other `TaskCard` states.** `surface` fill, `Radius.lg`, `Spacing.md` padding, 0.5pt `separator` outline.

- **Title row:** the task name (`cardTitle`) on the left; on the right, the `flame.fill` icon (`streak` color) and the streak in `cardStreak`, short or days-only following the owner's toggle. The streak's `IconBadge` sits on the left of the whole card, `Spacing.sm` before the name and status rows.
- **Status row** (`xxs` below the title): the `StatusPill`, then the meta line in `meta` / `textSecondary` next to it, `Spacing.xs` apart. At accessibility text sizes the meta line wraps below the pill.

| State | Pill | Meta line | Notes |
|---|---|---|---|
| **Done** | `done` | "Checked in 6:42 PM · Next: Friday" | Task name and streak in `textSecondary`. Shown inside the expanded "Done today" row. |
| **Upcoming** (later today) | `upcoming` "Opens 9:00 PM" | "2 skips left" | — |
| **Skipped today** | `skipped` | "No skips left" | Shown inside the expanded "Done today" row. |
| **Missed today** | `missed` | — | Streak-ended lines (below) |

A done task can't be checked in again until its next scheduled window. On the task screen its Check in button stays disabled and reads "Done today".

**Streak-ended lines** (shown on a card after a streak breaks), stacked below the status row with `xxs` spacing:

- Line 1, `meta` / `danger`: "Streak ended Friday at 3w 3d"
- Line 2, `meta` / `textSecondary`: "Longest: 5w 1d · Starts fresh today"
- How long these stay visible is **(open)**. For now, show them until the next check-in on that task.

### 4.2 Home, empty state

This is shown when there are no active streaks at all. The header stays (gear, greeting, Today, the date, and +); the "This week" row, the week strip, and the status line are hidden. The rest of the screen is centered vertically and horizontally:

- An 88pt circle in `accent` fill with a 32pt `plus` icon in `onAccent`. Tapping it opens Create Task.
- `Spacing.lg` below the circle: "Start your first streak" in `emptyTitle` / `textPrimary`.
- `Spacing.xs` below that: "Pick the days, a time window, and how many skips you get each week." in `subhead` / `textSecondary`, centered, max width 260pt.

There are no intro screens and no onboarding.

### 4.3 Create / Edit Task — `Views/TaskForm/TaskFormView.swift`

One view serves both create and edit, presented as a sheet.

**Top bar:**

- Left: "Cancel" in `body` / `accentText`.
- Center: "New streak" or "Edit streak" in `cardTitle`.
- Right: empty, for balance.

**Fields,** top to bottom, separated by `Spacing.xl`. Each has a label in `caption` / `textSecondary`, `Spacing.xs` above the field:

1. **Name**
   - A text field with `surface` fill, `Radius.md`, 0.5pt `separator` stroke, 12pt padding, and `body` text.
   - Placeholder: "e.g. Gym". Max 40 characters. Leading and trailing spaces are trimmed.
2. **Color and icon** (`StreakStylePicker`)
   - A row of the 8 streak colors (section 1.1b) as 32pt circles in their `main`, spread evenly across the full width. The selected one gets a 2pt `textPrimary` ring with a 2pt gap. Each has a 44pt tap target and a VoiceOver label with the color name ("Coral").
   - `Spacing.sm` below: a grid of the streak icons, 6 columns, 44pt cells, `Radius.md`, `Spacing.xs` apart. Icons in `badgeIcon` / `textSecondary`. The selected cell gets the chosen color's `soft` fill with the icon in its `main`. VoiceOver reads each icon's name ("Dumbbell").
   - Defaults for a new streak: section 1.1b.
3. **Which days**
   - Seven `DayChip`s, M T W T F S S (Monday first), spread evenly across the full width.
4. **Time window**
   - Two equal boxes side by side with an `xs` gap. Each box has `surface` fill, `Radius.md`, and a 0.5pt `separator` stroke. Inside each is a small "From" / "To" in `caption` / `textTertiary`, with the time below it in `body`.
   - Tapping a box shows Apple's time picker (hour and minute).
   - The default for a new task is 7:00 – 9:00 AM.
5. **Skips per week**
   - A stepper row: `surface` fill, `Radius.md`, 0.5pt `separator` stroke. It has a `minus` button on the left and a `plus` button on the right, both `accentText` with 44pt tap targets, and the number in the center in `statValue`.
   - The range is 0 to the number of selected days, and it's clamped down if days are deselected.
   - `Spacing.xs` below it is a **live helper line** in `meta` / `textSecondary`, using the task's name (or "task" if the name is empty):
     - 0 skips: "No skips — every Gym day counts."
     - Some skips: "You can miss 1 of your 4 Gym days each week and keep your streak."
     - Skips equal to the number of days: "You can skip every Gym day. Your streak won't break — but it won't grow either."

**Edit mode only:** when the owner changes the days or skip count, show a note under that field in `meta` / `textSecondary`: "Starting next week: 2 skips (this week: 1)." Changes to the name or time window apply immediately and show no note.

**Bottom:**

- A `PrimaryButton`, "Create task" or "Save changes", `Spacing.xl` below the last field.
- It's disabled until the name is non-empty, at least one day is selected, and the end time is after the start time.
- If the times are invalid, show "End time must be after start time." in `meta` / `danger` under the time window.
- Windows that cross midnight are **(open)**. For now, they aren't allowed.


**Edit mode only — archive and delete,** `Spacing.xxl` below the Save button, `Spacing.xs` apart:

- **"Archive streak"** (`SecondaryButton`) → `AppDialog`: title "Archive Gym?", body "It'll stop reminding you and leave your Today screen. Your photos and best streak are kept, and you can restore it anytime from Settings." Buttons: **"Cancel"** (highlighted) and "Archive" (`SecondaryButton`). Archiving ends the current streak but keeps the best streak and all photos, closes the form, and returns to the tab's first screen.
- **"Delete streak"** (`DangerTextButton`) → `AppDialog`: title "Delete Gym?", body "This permanently deletes the streak and all its photos." Buttons: **"Cancel"** (highlighted) and "Delete" (`DangerTextButton`). Deleting closes the form and returns to the tab's first screen.

### 4.4 Task screen — `Views/TaskDetail/TaskDetailView.swift`

**Top bar:**

- Left: a back button (`chevron.left`, `accentText`).
- Right: "Edit" in `body` / `accentText`, which opens TaskFormView in edit mode.

**Content,** top to bottom:

1. **Header**
   - The streak's `IconBadge` on the left, `Spacing.sm` before the task name in `screenTitle`.
   - `xxs` below it, the schedule summary in `meta` / `textSecondary`, e.g. "Mon, Tue, Thu, Fri · 6:00 – 8:00 PM".
2. **Stats** (`Spacing.md` above)
   - Two `StatTile`s side by side with a `Spacing.sm` gap:
     - "Streak" showing the short or days-only streak, e.g. "3w 2d"
     - "Skips left this week" showing "1 of 1"
   - `xs` below, in `caption` / `textTertiary`: "Longest: 5w 1d".
   - The weeks/days format follows **Settings → Show streaks as**. The Streak tile is not tappable.
3. **This week** (`Spacing.xl` above)
   - A `sectionHeader`, then one `WeekDayCircle` per **scheduled** day only, spread evenly. Unscheduled days are not shown.
4. **Actions** (`Spacing.xl` above)
   - `PrimaryButton` "Check in" (`camera.fill`) and `SecondaryButton` "Use a skip", side by side, equal width, `xs` gap.
   - **Check in** is disabled outside the window, and its label changes to "Opens 6:00 PM" before the window or "Closed" after it. When done today, it's disabled and reads "Done today".
   - **Use a skip** is disabled when no skips are left ("No skips left"), when already checked in or skipped today, or after the window closes.
5. **Recent check-ins** (`Spacing.xl` above)
   - A `sectionHeader` on the left and "See all" in `meta` / `accentText` on the right, which opens History.
   - Below it, a 4-column grid of `PhotoThumbnail`s, `xs` gaps, showing the latest 4.
   - With none: "No check-ins yet." in `meta` / `textTertiary`.

### 4.5 Skip confirmation — `Views/Skip/SkipConfirmationView.swift`

This is a centered dialog over a `scrim`. It is not Apple's default alert, because we need control over which button is highlighted.

- **Card:** `surface` fill, `Radius.xl`, padding `lg` (20), width = screen width − 48 (max 340), all text centered.
- **Title** (`cardTitle`): "Use your last skip?" if this is the last skip, otherwise "Use a skip?"
- **Body** (`subhead` / `textSecondary`, `xs` below the title). First sentence: "You have {N} {Task} days left this week, including today." Then a second sentence:
  - Last skip, 1 scheduled day after today: "If you skip today, you'll have to make it {Weekday} to keep your streak."
  - Last skip, 2 or more scheduled days after today: "If you skip today, you'll need to check in every remaining day this week to keep your streak."
  - Last skip, no scheduled days after today: "This keeps your streak, but you'll have no skips left until Monday."
  - Not the last skip: "You'll have {K} skip(s) left this week after this."
- **Buttons,** stacked vertically, `Spacing.xs` apart, `Spacing.lg` below the body:
  1. `PrimaryButton` **"Keep my skip"**. This is the highlighted one. It closes the dialog and changes nothing.
  2. `DangerTextButton` **"Use skip"**. It uses the skip, plays the warning haptic, and closes the dialog.
- Tapping the scrim counts as "Keep my skip."

### 4.6 Camera — `Views/CheckIn/CameraView.swift`

- Full screen, black background, live camera view filling the screen. **No photo-library button.**
- **Top bar,** white:
  - Left: `xmark` close button (44pt).
  - Center: "Gym · closes 8:00 PM" in `subhead`.
- **Bottom,** centered: a shutter button, a 72pt white circle inside a 4pt white ring with a 4pt gap.
- **Bottom right:** a `camera.rotate` button (44pt, white) to switch between front and back cameras. Front is useful for skincare.
- If the window closes while the camera is open, show "The window closed at 8:00 PM." and dismiss.
- **The iPhone simulator has no camera.** In DEBUG builds running on the simulator, show a "Use sample photo" button in place of the live view.

### 4.7 Photo preview — `Views/CheckIn/PhotoPreviewView.swift`

- Black background, the captured photo fitted to the screen.
- Top: "Gym · closes 8:00 PM" in `subhead`, white.
- Bottom: `SecondaryButton` "Retake" and `PrimaryButton` "Submit", side by side, equal width, `xs` gap, `Spacing.lg` from the bottom safe area. On this screen only, "Retake" has a translucent white fill (white at 15%) and a white label, so it reads on black.

### 4.8 Streak celebration — `Views/CheckIn/StreakCelebrationView.swift`

Shown full screen right after Submit. It replaces the old check-in success screen and settles the earlier "full screen vs. popup" question: **full screen, then it closes on its own.**

- `background` color, content centered vertically:
  - Behind the flame: a soft **radial glow** in the checked-in streak's `main`, about 280pt across, from 35% opacity in the middle fading to transparent at the edge. It grows and fades in with the pop (just there with Reduce Motion or Celebration animation off).
  - A large `flame.fill` (`celebrationIcon`, about 96pt) in `streak` color. It pops in, scaling from 0.5 to 1.0 with a spring, and the **success haptic** plays.
  - Below it, the streak **in days** as a big number in `celebrationNumber` / `textPrimary` (e.g. "23"). It counts up quickly from the previous value (22 → 23).
  - Directly under the number: "day streak" in `subhead` / `textSecondary`.
  - `Spacing.lg` below: "{Task} done" in `successTitle` / `textPrimary`.
  - `xxs` below, in `meta` / `textTertiary`, the week line: "1 more to finish the week", "2 more to finish the week", or "Week complete". If checking in gave back a skip used earlier today, a second line: "Your skip is back — 1 skip left".
- The celebration always shows the streak in days, even when the owner's toggle is set to weeks + days.
- It **closes automatically after 2.5 seconds** and returns to the screen the check-in started from. **Tapping anywhere** closes it early. There's no button.
- Reduce Motion: no pop and no count-up; the final number shows straight away. It still closes on its own.
- VoiceOver reads it as one element: "23 day streak. Gym done. 1 more to finish the week."

**Closing the task.** Back on the Today tab, the hero card animates out of the Today list into the "Done today" row (its count goes up by one), and the summary ring fills to its new value.

### 4.9 History — `Views/History/HistoryView.swift`

- Title: the task name with "History" (e.g. "Gym History"), in `cardTitle` in the top bar.
- Grouped by month, newest first. Month headers ("October 2026") use `sectionHeader`.
- A 3-column grid of `PhotoThumbnail`s, `xs` gaps. Under each one, the date and time in `caption` / `textTertiary` ("Oct 1 · 6:42 PM").
- Tapping a photo opens it full screen on black, with its date and time at the top and a close button.
- Empty: "No check-ins yet. Your photos will show up here." in `subhead` / `textSecondary`, centered.

---

### 4.10 Streaks tab — `Views/Habits/HabitsView.swift`

On screen these are **streaks**; the code keeps the name Habits.

**Header** (scrolls with the content, no navigation bar title): "Streaks" in `screenTitle` on the left; a + button on the right (`plus`, `accentText`, 44pt), which opens Create Task.

**"Active"** section (`sectionHeader` / `textTertiary`): every habit that isn't archived, sorted by current streak (total check-ins in the streak), highest first; ties keep their order. One `HabitRow` per habit, `Spacing.sm` apart:

- `surface` fill, `Radius.lg`, `Spacing.md` padding, 0.5pt `separator` outline.
- Far left: the streak's `IconBadge`, `Spacing.sm` before the text.
- Left, stacked with `xxs` spacing: name in `cardTitle` / `textPrimary`; schedule summary in `meta` / `textSecondary` ("Mon, Tue, Thu, Fri · 6:00 – 8:00 PM"); today's `StatusPill` (open / done / upcoming / skipped / missed), or "Not today" in `meta` / `textTertiary` if it isn't scheduled today.
- Right, trailing-aligned: `flame.fill` (`streak`) and the current streak in `cardStreak`, following Settings → Show streaks as; below it "Best: 5w 1d" in `caption` / `textTertiary`.
- Tapping a row opens its task screen (section 4.4).

**"Archived · 1"** `DisclosureRow` at the bottom, collapsed by default (remembered until the app closes). Hidden when nothing is archived. Expanded, it lists archived streaks as rows: `surface` fill, `Radius.lg`, `Spacing.md` padding, separator outline; the `IconBadge`, then the name in `cardTitle` / `textTertiary` on the left, "Best: 5w 1d" in `caption` / `textTertiary` on the right, `chevron.right`. Tapping one opens the archived streak screen (section 4.11).

**Empty** (no active habits): `EmptyStateView` centered under the header. The Archived row still shows below it if anything is archived.

### 4.11 Archived streak — `Views/Habits/ArchivedHabitView.swift`

Pushed onto the navigation stack (back button `chevron.left`, `accentText`).

- Name in `screenTitle`, schedule summary in `meta` / `textSecondary`, "Archived" in `caption` / `textTertiary`.
- `StatTile` "Best streak" with the best streak (following Settings → Show streaks as), and `StatTile` "Photos" with the number of check-in photos kept, side by side.
- `Spacing.xl` below: **"Restore"** (`PrimaryButton`). Restoring brings the habit back to the Active list right away with a fresh streak starting from its next scheduled day; the best streak is kept. Then it returns to the previous screen.
- `Spacing.xs` below: **"Delete permanently"** (`DangerTextButton`) → the same "Delete Gym?" `AppDialog` as section 4.3.

### 4.12 History — `Views/History/AllHistoryView.swift`

Not a tab. **Pushed from Today** with a standard navigation push: the "History" link above the week strip, or a tapped past day in the week strip.

- Standard navigation bar: the system back button at the top left (chevron with "Today"), and swiping from the left edge goes back. Title **"History"** in the large title style.
- **The tab bar hides** on this screen so it feels like its own page; it comes back when you return to Today.
- **Opened from a tapped day:** it scrolls so that day's header sits at the top. If that day has nothing in the timeline, its header still shows, with "Nothing scheduled" (nothing was scheduled that day) or "No check-ins" (something was, but nothing was checked in, skipped, or missed) in `meta` / `textTertiary` under it.

**Filter chips** in a horizontal scroll under the title (`Spacing.xs` apart): "All" first, then one `FilterChip` per habit that has anything in its history (archived habits included, since their photos are kept), in the Streaks tab order. "All" is selected by default. A selected streak chip uses that streak's `solid` fill with an `onAccent` label; a selected "All" uses `accent`.

**Timeline**, grouped by day, newest first. Day headers in `sectionHeader` / `textTertiary`: "Today", "Yesterday", then "Thursday, Sep 24". Within a day, newest first. Rows `Spacing.sm` apart:

- **Check-in:** the streak's `IconBadge` on the left; then the task name in `cardTitle` / `textPrimary` and the time in `meta` / `textSecondary` ("6:42 PM"); a 56pt `PhotoThumbnail` on the right. Tapping it opens the photo in the `PhotoViewer`.
- **Skip:** a text row with no photo: `minus` icon and "Skipped Gym" in `meta` / `textSecondary`.
- **Miss:** a text row with no photo: `xmark` icon and "Missed Guitar · streak ended at 2w 1d" in `meta` / `danger` (just "Missed Guitar" if no streak ended).

**Empty** (nothing for the current filter): "No check-ins yet. Your photos will show up here." in `subhead` / `textSecondary`, centered.

### 4.13 Settings — `Views/Settings/SettingsView.swift`

Opened from the gear on Today, as a sheet (swipe down or "Done" to close). The navigation bar shows only **"Done"** at the top right (`body`, semibold, `accentText`); everything below is unchanged.

A standard iOS grouped list (inset grouped), on `background`, with rows on `surface`. Row labels in `body` / `textPrimary`, values in `body` / `textSecondary`, section headers in `sectionHeader` / `textTertiary`, footers in `meta` / `textSecondary`. Title: "Settings" in `screenTitle` above the list (scrolls with it). Pickers use the standard menu picker, tinted `accentText`. Everything here is saved on the device.

**You** (the first section)
- "Your name" on the left in `body` / `textPrimary`; a text field on the right, right-aligned, placeholder "Optional", in `body` / `textSecondary`. Up to 30 characters; leading and trailing spaces are trimmed. Saved on the device.
- Footer: "Only used for your greeting. It stays on this iPhone."

**Display**
- "Show streaks as" → "Weeks and days" (default) / "Days only". This is the only weeks/days switch in the app.
- "Appearance" → "System" (default) / "Light" / "Dark".

**Reminders**
- Only when iPhone notifications are turned off for this app (denied in the iPhone's Settings): a warning row first, `dangerSoft` background, `exclamationmark.triangle.fill` in `danger`, "Notifications are off. Your streaks can end without a warning." in `subhead` / `textPrimary`, and a "Turn on" button in `accentText` that opens this app's page in the iPhone Settings app.
- "Repeat during window" → "Every 10 min" / "Every 15 min" (default) / "Every 30 min".
- "Last-call warning" → "10 min before" / "15 min before" (default) / "30 min before".
- Footer: "Reminders are always on for every streak. They stop as soon as you check in or use a skip."

**Feel**
- "Vibrations" → toggle, on by default. Off turns off every haptic.
- "Celebration animation" → toggle, on by default. Off: the celebration shows the flame and number without the pop and count-up.

**Streaks**
- "Archived streaks" → shows the count on the right and opens the archived list (the same rows as the Streaks tab's Archived section, always expanded). Empty: "No archived streaks." in `subhead` / `textSecondary`.

**Your data**
- "Photo storage" → read-only, e.g. "142 photos · 38 MB".
- "Delete all data" in `body` / `danger` → two `AppDialog`s in a row:
  1. "Delete everything?" / "All streaks and photos will be permanently deleted from this iPhone." — **"Cancel"** (highlighted) and "Continue" (`SecondaryButton`).
  2. "This can't be undone." (no body) — **"Cancel"** (highlighted) and "Delete everything" (`DangerTextButton`).
  Afterwards the sheet closes and the app shows the Today tab in its empty state. Settings themselves are kept.
- Footer: "Everything stays on this iPhone. Nothing is uploaded."

**About**
- "Version" → read-only, e.g. "0.1.0 (1)" (version and build number).

**Developer** (DEBUG builds only, not compiled into Release)
- "Design Gallery" → opens the gallery. There is no paintbrush button on the Today tab any more.

---

## 5. Accessibility

- Support Dynamic Type up to the largest accessibility sizes. Layouts must wrap rather than clip: side-by-side buttons stack vertically at accessibility sizes.
- Every icon-only button needs a VoiceOver label: "Create task", "Back", "Close camera", "Take photo", "Switch camera".
- **Task cards** read as one element, e.g. "Gym. Open now. Closes 8 PM. Streak 12 days. 1 skip left." The Check in button is still reachable separately.
- **Week circles** read as "Monday, done", "Thursday, today", and so on.
- Text colors listed above meet contrast guidelines against their backgrounds. Don't introduce new combinations without checking.

---

## 6. Copy reference

All user-facing text, in one place. Put these in a single `Strings` file so wording can be changed later without hunting through the code.

| Where | Text |
|---|---|
| Home title | Today |
| Section headers | Today · Not today · This week · Recent check-ins |
| Empty state | Start your first streak / Pick the days, a time window, and how many skips you get each week. |
| Pills | Open now · Done · Opens {time} · Skipped · Missed |
| Today status line | {n} of {m} done today · All done for today · Rest day · Next: {task} at {time} · Next: {task} tomorrow at {time} · Next: {task} {weekday} at {time} · {task} is open now |
| This week row | This week · History |
| Hero card | Closes in {h}h {m}m · Closes in {h}h · Closes in {m}m · Check in |
| Card meta | Checked in {time} · Next: {day} · {n} skips left |
| Streak ended | Streak ended {weekday} at {short streak} / Longest: {short streak} · Starts fresh today |
| Form | New streak · Edit streak · Cancel · Name · Color and icon · Which days · Time window · From · To · Skips per week · Create streak · Save changes |
| Form errors | End time must be after start time. |
| Next-week note | Starting next week: {n} skips (this week: {m}) |
| Task screen | Edit · Streak · Skips left this week · Longest: {streak} · Check in · Use a skip · See all · No check-ins yet. |
| Disabled buttons | Opens {time} · Closed · Done today · No skips left |
| Skip dialog | Use your last skip? · Use a skip? · Keep my skip · Use skip |
| Camera | {Task} · closes {time} · The window closed at {time}. · Use sample photo |
| Preview | Retake · Submit |
| Celebration | {days} · day streak · {Task} done · {n} more to finish the week · Week complete · Your skip is back — {n} skip left |
| History | {Task} History · No check-ins yet. Your photos will show up here. |
| Tab bar | Today · Streaks |
| Today header | Settings (VoiceOver, gear) · Create streak (VoiceOver, +) · Good morning · Good afternoon · Good evening · , {name} · Today |
| Week strip (VoiceOver) | {weekday}, all done. Opens history. · {weekday}, {n} of {m} done. Opens history. · {weekday}, nothing scheduled. Opens history. · {weekday}, today, {n} of {m} done · {weekday} |
| History screen | History · Nothing scheduled · No check-ins |
| Colors (VoiceOver) | Coral · Orange · Green · Teal · Blue · Indigo · Pink · Purple |
| Icons (VoiceOver) | Dumbbell · Running · Walking · Bicycle · Drop · Sparkles · Book · Pencil · Brain · Guitar · Music · Paintbrush · Fork and knife · Cup · Leaf · Bed · Moon · Sun · Heart · First aid · House · Cart · Laptop · Star |
| Today tab | Coming up · Done today · {n} · {day}, {time} |
| Streaks tab | Streaks · Active · Archived · {n} · Not today · Best: {streak} |
| Archived streak | Archived · Best streak · Photos · Restore · Delete permanently |
| History tab | History · All · Today · Yesterday · Skipped {Task} · Missed {Task} · Missed {Task} · streak ended at {streak} · No check-ins yet. Your photos will show up here. |
| Settings | Settings · You · Your name · Optional · Only used for your greeting. It stays on this iPhone. · Display · Show streaks as · Weeks and days · Days only · Appearance · System · Light · Dark · Reminders · Notifications are off. Your streaks can end without a warning. · Turn on · Repeat during window · Every 10 min · Every 15 min · Every 30 min · Last-call warning · 10 min before · 15 min before · 30 min before · Reminders are always on for every streak. They stop as soon as you check in or use a skip. · Feel · Vibrations · Celebration animation · Streaks · Archived streaks · No archived streaks. · Your data · Photo storage · {n} photos · {size} · No photos · Delete all data · Everything stays on this iPhone. Nothing is uploaded. · About · Version · Developer · Design Gallery · Done |
| Edit streak | Archive streak · Delete streak |
| Archive dialog | Archive {Task}? · It'll stop reminding you and leave your Today screen. Your photos and best streak are kept, and you can restore it anytime from Settings. · Cancel · Archive |
| Delete dialog | Delete {Task}? · This permanently deletes the streak and all its photos. · Cancel · Delete |
| Delete-all dialogs | Delete everything? · All streaks and photos will be permanently deleted from this iPhone. · Cancel · Continue · This can't be undone. · Delete everything |
