# Habit App — Design Spec

The visual reference for every screen in v1. Read together with `docs/context.md`, which holds the product rules. If the two conflict on **behavior**, `context.md` wins. If they conflict on **looks**, this file wins. Anything marked **(open)** is undecided: build the default described here, and flag it to the owner instead of inventing something new.

The overall feel is calm, clean, and quietly encouraging. It should never feel punishing. The app uses one accent color, lots of breathing room, no shadows, no gradients, and no decoration that doesn't carry meaning.

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

### 1.2 Typography

Use the system font (SF Pro) through **Dynamic Type text styles**, so text scales with the user's iPhone text-size setting. Expose these as `Font.app.<name>` in `DesignSystem/AppFonts.swift`. Put `.monospacedDigit()` on any number that changes (streaks, counts, times) so digits don't jitter.

| Name | Text style + weight | Approx. size | Used for |
|---|---|---|---|
| `screenTitle` | `.title`, bold | 28 | "Today", task name on the task screen |
| `successTitle` | `.title2`, bold | 22 | "Gym done" |
| `emptyTitle` | `.title3`, semibold | 20 | "Start your first habit" |
| `statValue` | `.title3`, semibold, monospaced digits | 20 | "3w 2d", "1 of 1" |
| `cardTitle` | `.headline` (semibold) | 17 | Task name on a card, dialog title, form screen title |
| `button` | `.body`, semibold | 17 | All button labels |
| `body` | `.body`, regular | 17 | Form field text |
| `subhead` | `.subheadline`, regular | 15 | Date line, dialog body, empty-state body |
| `meta` | `.footnote`, regular | 13 | Card meta line, helper text, schedule line |
| `sectionHeader` | `.footnote`, semibold | 13 | "Today", "Not today", "This week", "Recent check-ins" |
| `pill` | `.caption`, semibold | 12 | Status pills |
| `caption` | `.caption`, regular | 12 | Stat tile labels, field labels, day labels under circles, photo dates |

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
- **Card outline:** a 0.5pt `separator` stroke. The open-task card uses a 1.5pt `accent` stroke instead.
- **Shadows and gradients:** none.
- **Icons:** SF Symbols only, sized to match the text next to them.
  - `plus` (create task, empty state)
  - `camera.fill` (Check in)
  - `flame.fill` (streaks, in `streak` color)
  - `checkmark` (done)
  - `xmark` (missed, close camera)
  - `minus` (skipped day)
  - `chevron.left` (back)
  - `camera.rotate` (flip camera)
  - `photo` (placeholder thumbnail)

### 1.6 Motion and haptics

- Keep motion subtle and quick: system default animations, about 0.25s.
- **Check-in success:** the checkmark circle scales from 0.6 to 1.0 with a gentle spring, and a **success haptic** plays.
- **Confirming "Use skip":** a **warning haptic** plays.
- Respect the Reduce Motion setting: skip the scale animation when it's on.

---

## 2. Reusable components

Put each in its own file under `Views/Components/`, with these exact names:

- **`PrimaryButton`**
  - 50pt tall, `accent` fill, `onAccent` label in `Font.app.button`, `Radius.md`, optional leading SF Symbol.
  - Disabled: `surfaceMuted` fill, `textTertiary` label.
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
  - The home-screen card. Every state is described in section 4.1.
- **`StatTile`**
  - `surfaceMuted` fill, `Radius.md`, padding `sm` (12).
  - Label in `Font.app.caption` / `textSecondary`, with the value below it in `Font.app.statValue` / `textPrimary`.
- **`WeekDayCircle`**
  - 32pt circle with a weekday label below it ("Mon") in `Font.app.caption` / `textSecondary`, 4pt gap. States:
    - `done`: `successSoft` fill, `success` checkmark
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

---

## 4. Screens

Put screens in `Views/<Area>/` with these exact names. Every screen uses `Color.app.background` behind its content and side padding of `Spacing.lg`.

### 4.1 Home — `Views/Home/HomeView.swift`

**Header:**

- Left: "Today" in `screenTitle`, with the date below it in `subhead` / `textSecondary`, e.g. "Thursday, October 1".
- Right: a + button, `plus` icon, `accentText`, 44pt tap target. Tapping it opens Create Task.
- No navigation bar title. The header scrolls with the content.

**Body:** a scrolling list with two sections, each headed with `sectionHeader` / `textTertiary`.

- **"Today":** tasks scheduled today, **sorted by window start time**. Done tasks stay in place.
- **"Not today":** the remaining tasks, sorted by their next scheduled window. Hide this section if it's empty.

Cards are separated by `Spacing.sm`. **Tapping anywhere on a card** (other than its button) opens that task's screen.

**`TaskCard` states.** Every card has `surface` fill, `Radius.lg`, and `Spacing.md` padding. The title row has the task name (`cardTitle`) on the left and a `StatusPill` on the right. The meta line below it uses `meta` / `textSecondary`.

| State | Pill | Meta line | Extras |
|---|---|---|---|
| **Open** (window open, not done or skipped) | `open` | "Closes 8:00 PM · 🔥 12 days · 1 skip left" | 1.5pt `accent` outline. A full-width `PrimaryButton` "Check in" with `camera.fill`, `Spacing.sm` below the meta line. **No skip button here.** |
| **Done** | `done` | "Checked in 7:42 AM · 🔥 30 days" | — |
| **Upcoming** (later today) | `upcoming` "Opens 9:00 PM" | "🔥 5 days · 2 skips left" | — |
| **Skipped today** | `skipped` | "🔥 12 days · No skips left" | — |
| **Missed today** | `missed` | — | Streak-ended lines (below) |
| **Not today** | none | "Next: Friday, 8:00 – 10:00 PM · 🔥 4 days" | Task name in `textTertiary` instead of `textPrimary` |

(🔥 above means `StreakLabel`, the `flame.fill` icon in `streak` color, not an emoji.) The streak in the meta line uses the short or days-only format, following the owner's toggle.

**Streak-ended lines** (shown on a card after a streak breaks), stacked below the meta line with `xxs` spacing:

- Line 1, `meta` / `danger`: "Streak ended Friday at 3w 3d"
- Line 2, `meta` / `textSecondary`: "Longest: 5w 1d · Starts fresh today"
- How long these stay visible is **(open)**. For now, show them until the next check-in on that task.

### 4.2 Home, empty state

This is shown when there are no tasks. The header stays (Today, the date, and +). The rest of the screen is centered vertically and horizontally:

- An 88pt circle in `accent` fill with a 32pt `plus` icon in `onAccent`. Tapping it opens Create Task.
- `Spacing.lg` below the circle: "Start your first habit" in `emptyTitle` / `textPrimary`.
- `Spacing.xs` below that: "Pick the days, a time window, and how many skips you get each week." in `subhead` / `textSecondary`, centered, max width 260pt.

There are no intro screens and no onboarding.

### 4.3 Create / Edit Task — `Views/TaskForm/TaskFormView.swift`

One view serves both create and edit, presented as a sheet.

**Top bar:**

- Left: "Cancel" in `body` / `accentText`.
- Center: "New task" or "Edit task" in `cardTitle`.
- Right: empty, for balance.

**Fields,** top to bottom, separated by `Spacing.xl`. Each has a label in `caption` / `textSecondary`, `Spacing.xs` above the field:

1. **Name**
   - A text field with `surface` fill, `Radius.md`, 0.5pt `separator` stroke, 12pt padding, and `body` text.
   - Placeholder: "e.g. Gym". Max 40 characters. Leading and trailing spaces are trimmed.
2. **Which days**
   - Seven `DayChip`s, M T W T F S S (Monday first), spread evenly across the full width.
3. **Time window**
   - Two equal boxes side by side with an `xs` gap. Each box has `surface` fill, `Radius.md`, and a 0.5pt `separator` stroke. Inside each is a small "From" / "To" in `caption` / `textTertiary`, with the time below it in `body`.
   - Tapping a box shows Apple's time picker (hour and minute).
   - The default for a new task is 7:00 – 9:00 AM.
4. **Skips per week**
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

### 4.4 Task screen — `Views/TaskDetail/TaskDetailView.swift`

**Top bar:**

- Left: a back button (`chevron.left`, `accentText`).
- Right: "Edit" in `body` / `accentText`, which opens TaskFormView in edit mode.

**Content,** top to bottom:

1. **Header**
   - The task name in `screenTitle`.
   - `xxs` below it, the schedule summary in `meta` / `textSecondary`, e.g. "Mon, Tue, Thu, Fri · 6:00 – 8:00 PM".
2. **Stats** (`Spacing.md` above)
   - Two `StatTile`s side by side with a `Spacing.sm` gap:
     - "Streak" showing the short or days-only streak, e.g. "3w 2d"
     - "Skips left this week" showing "1 of 1"
   - `xs` below, in `caption` / `textTertiary`: "Longest: 5w 1d".
   - **Days/weeks toggle (proposal):** tapping the Streak tile switches the format app-wide between weeks + days and days only, and the choice is remembered. Flag this to the owner, since where the toggle lives is **(open)**.
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

### 4.8 Check-in success — `Views/CheckIn/CheckInSuccessView.swift`

Full screen vs. a quick popup is **(open)**. Build the full-screen version below, and keep it easy to swap.

- `background` color, content centered vertically:
  - A 72pt circle in `successSoft` with a 32pt `checkmark` in `success`, using the spring animation and success haptic.
  - `Spacing.md` below: "{Task} done" in `successTitle`.
  - `xs` below: "Streak: 3 weeks 3 days" in `subhead` / `textSecondary` (long style, or days-only if toggled).
  - `xxs` below, in `meta` / `textTertiary`:
    - "1 more to finish the week" / "2 more to finish the week"
    - "Week complete" when no scheduled days are left
    - If a skip was refunded: "Your skip is back — 1 skip left"
- `SecondaryButton` "Back to today", pinned `Spacing.lg` above the bottom safe area. It returns to Home.

### 4.9 History — `Views/History/HistoryView.swift`

- Title: the task name with "History" (e.g. "Gym History"), in `cardTitle` in the top bar.
- Grouped by month, newest first. Month headers ("October 2026") use `sectionHeader`.
- A 3-column grid of `PhotoThumbnail`s, `xs` gaps. Under each one, the date and time in `caption` / `textTertiary` ("Oct 1 · 6:42 PM").
- Tapping a photo opens it full screen on black, with its date and time at the top and a close button.
- Empty: "No check-ins yet. Your photos will show up here." in `subhead` / `textSecondary`, centered.

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
| Empty state | Start your first habit / Pick the days, a time window, and how many skips you get each week. |
| Pills | Open now · Done · Opens {time} · Skipped · Missed |
| Card meta | Closes {time} · Checked in {time} · Next: {day}, {window} |
| Streak ended | Streak ended {weekday} at {short streak} / Longest: {short streak} · Starts fresh today |
| Form | New task · Edit task · Cancel · Name · Which days · Time window · From · To · Skips per week · Create task · Save changes |
| Form errors | End time must be after start time. |
| Next-week note | Starting next week: {n} skips (this week: {m}) |
| Task screen | Edit · Streak · Skips left this week · Longest: {streak} · Check in · Use a skip · See all · No check-ins yet. |
| Disabled buttons | Opens {time} · Closed · Done today · No skips left |
| Skip dialog | Use your last skip? · Use a skip? · Keep my skip · Use skip |
| Camera | {Task} · closes {time} · The window closed at {time}. · Use sample photo |
| Preview | Retake · Submit |
| Success | {Task} done · Streak: {long streak} · {n} more to finish the week · Week complete · Your skip is back — {n} skip left · Back to today |
| History | {Task} History · No check-ins yet. Your photos will show up here. |
