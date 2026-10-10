# Habit App — Design Spec

> **Naming:** on screen, each habit is called a **streak** (the Streaks tab, "New streak"). In code and in this spec, "task" and "habit" still mean the same thing.

The visual reference for every screen in v1. Read together with `docs/context.md`, which holds the product rules. If the two conflict on **behavior**, `context.md` wins. If they conflict on **looks**, this file wins. Anything marked **(open)** is undecided: build the default described here, and flag it to the owner instead of inventing something new.

The overall feel is **playful and game-like**: bold, chunky, and bouncy, with real energy, but our own design (no borrowed artwork, characters, or names). It should never feel punishing. The app is **always dark navy**, uses **one brand color (flame orange)** for app-wide controls and **a bright color per streak**, flat colors only (**no gradients, no shadows**), chunky 3D buttons and cards with a darker "lip" edge, the **Nunito** typeface everywhere, and short sounds and haptics that make actions feel physical.

> **Sections 1 and 2 are the source of truth for every color, font, and component.** Some screen descriptions in section 4 predate this restyle; wherever they name an old token or component, read it through this mapping: `accent` / `accentText` → `flame`; `accentSoft` → `flame` text (no box); `onAccent` → `textOnBright`; `separator` → `border`; `streak` (the flame icon color) → `flame`; `PrimaryButton` → `ChunkyButton(.primary)`; `SecondaryButton` → `ChunkyButton(.secondary)`; `DangerTextButton` → `ChunkyButton(.danger)`; inverted hero button → `ChunkyButton(.white)`; a streak's `solid` / `deep` / `soft` → its `main` / `lip` / `badge`. Gradients mentioned anywhere are gone.

---

## 1. Design system

All values live in `DesignSystem/` and are used everywhere through these names. **Never hard-code a color, font, spacing value, or corner radius inside a view.**

### 1.1 Colors — `DesignSystem/AppColors.swift`

**The app is always dark.** There is no light mode and no appearance setting; dark is forced app-wide (`UIUserInterfaceStyle` = Dark in Info.plist, plus `.preferredColorScheme(.dark)` at the root). Each color is a single-value color set in `Resources/Assets.xcassets/Colors/`, exposed as `Color.app.<name>`.

**Neutrals**

| Name | Value | Used for |
|---|---|---|
| `background` | `#131F24` | Screen background behind everything |
| `surface` | `#1B2A31` | Cards, tab bar, form fields, secondary buttons |
| `surfaceRaised` | `#22333B` | Dialog cards, stat tiles, today's week-strip circle |
| `surfaceMuted` | `#26363E` | Future week-strip days, photo placeholders, unselected chips |
| `border` | `#2E3D45` | 2pt card and field borders, card lips, secondary button lips |
| `textPrimary` | `#FFFFFF` | Titles, names, main text |
| `textSecondary` | `#A9B8C0` | Meta lines, helper text |
| `textTertiary` | `#6F818B` | Section headers, captions, unselected tabs, disabled labels |
| `textOnBright` | `#131F24` | Small text and icons on any bright fill |

**Bright colors**, each with a darker **lip** for the 3D edge (`<name>Lip`):

| Name | Fill | Lip | Used for |
|---|---|---|---|
| `flame` | `#FF9600` | `#CC7800` | **The brand color** (replaces the old accent): primary buttons, links, +, the week strip, the flame icon, the selected chip and day |
| `success` | `#58CC02` | `#46A302` | Done text, success buttons, toggles |
| `danger` | `#FF4B4B` | `#D33131` | Missed, streak ended, destructive labels |
| `info` | `#1CB0F6` | `#1899D6` | Secondary button labels, the selected tab |
| `gold` | `#FFC800` | `#E5A800` | Confetti (and later rewards) |
| `purple` | `#CE82FF` | `#A568CC` | Confetti (and later rewards) |

**Fixed extras**

| Name | Value | Used for |
|---|---|---|
| `disabled` / `disabledLip` | `#37464F` / `#2B3940` | Disabled buttons |
| `track` | `#37464F` | Empty part of progress bars and rings |
| `whiteButton` / `whiteButtonLip` | `#FFFFFF` / `#E5E5E5` | The Check in button on a hero card |
| `scrim` | black at 55% | Dim layer behind dialogs |
| `successSoft`, `dangerSoft`, `flameSoft` | the color at 20% | Small tinted backgrounds (missed day circle, notifications warning) |
| `onBrightMuted` / `onBrightFaint` | `textOnBright` at 75% / 15% | Secondary text and the icon badge on a hero card |
| `highlight` | white at 30% | The glossy stripe on progress bar fills |
| `cameraBackground` / `cameraForeground` | black / white | The camera, photo preview, and photo viewer stay black with white controls |

**Contrast rule:** on any **bright fill** (flame, success, danger, info, gold, purple, any streak color), small text and icons use **`textOnBright`** (dark navy), never white. White on a bright fill is allowed only for bold text **20pt or larger** — and for the week strip's done-day flame icon, which the owner asked for in white.

**No gradients anywhere.** Flat, bold color only.

**Flame character colors** (section 2b). Existing colors where they match, plus four new color sets:

| Name | Value | Used for |
|---|---|---|
| `flameEmberOutline` | `#8F5400` | The Ember's 3pt outline (its body is `flameLip`, its core `flame`) |
| `flameSparkCore` | `#FFB340` | The Spark's lighter inner core |
| `flameWhiteHot` | `#FFF6DB` | The white-hot core of Inferno, Wildfire, and Eternal; sparkles |
| `flameEternalOutline` | `#0F7FB5` | The Eternal's outline (its body is `info`) |

Spark to Wildfire use `flame` bodies with `flameLip` outlines and a `gold` core; Inferno and Wildfire add a `danger` outer layer (`dangerLip` outline); Wildfire's tongue tips are `purple`. Eyes are white with `textOnBright` pupils, mouths `textOnBright`, the worried sweat drop `info`. Locked forms on the Flame screen are `surfaceMuted` (`#26363E`) silhouettes.

### 1.1b Streak colors — `DesignSystem/StreakPalette.swift`

Each streak has one of 8 bright colors, each a `main` and a darker `lip`. Exposed as `StreakColor.<name>` with `.main`, `.lip`, and `.badge` (`main` at 20%, for icon badge backgrounds and selected icon cells). Single values (the app is always dark).

| Name | Main | Lip |
|---|---|---|
| `coral` | `#FF4B4B` | `#D33131` |
| `orange` | `#FF9600` | `#CC7800` |
| `yellow` | `#FFC800` | `#E5A800` |
| `green` | `#58CC02` | `#46A302` |
| `teal` | `#00CD9C` | `#00A47D` |
| `blue` | `#1CB0F6` | `#1899D6` |
| `purple` | `#CE82FF` | `#A568CC` |
| `pink` | `#FF86D0` | `#CC6BA6` |

Old colors map to the nearest new one: coral → coral, orange → orange, green → green, teal → teal, blue → blue, **indigo → purple**, pink → pink, purple → purple. (`yellow` is new.)

Rules:

- A streak's color marks **that streak** (its icon badge, its done days, its History chip, its hero card). `flame` stays the brand color for everything app-wide.
- The `flame.fill` streak icon is `flame` everywhere except on bright fills.

**Streak icons** (SF Symbols, all available on iOS 17): `dumbbell.fill`, `figure.run`, `figure.walk`, `bicycle`, `drop.fill`, `sparkles`, `book.fill`, `pencil`, `brain.head.profile`, `music.note`, `mic.fill`, `paintbrush.fill`, `fork.knife`, `cup.and.saucer.fill`, `leaf.fill`, `bed.double.fill`, `moon.fill`, `sun.max.fill`, `heart.fill`, `cross.case.fill`, `house.fill`, `cart.fill`, `laptopcomputer`, `star.fill`.

All 24 were checked at 20pt on a 40pt badge and read clearly. (`guitars.fill` was replaced by `music.note`, and `mic.fill` took `music.note`'s old slot; existing streaks were remapped.)

**Defaults for a new streak:** the first color (in the table's order) not used by an active streak (back to `coral` if all are taken), and an icon guessed from the name, case-insensitive: gym / lift → `dumbbell.fill`; run → `figure.run`; skin / face → `drop.fill`; read → `book.fill`; guitar → `music.note`; dishes / clean → `sparkles`; sleep → `bed.double.fill`; otherwise `star.fill`. The guess follows the name as it's typed until an icon is picked by hand.

### 1.2 Typography — `DesignSystem/AppFonts.swift`

**Nunito for all text** (SIL Open Font License; bundled as one variable font file, `Resources/Fonts/Nunito-Variable.ttf`, registered in `project.yml` → Info.plist `UIAppFonts`; credits in `docs/credits.md`). The app uses four of its named weights: **SemiBold** (`Nunito-SemiBold`), **Bold** (`Nunito-Bold`), **ExtraBold** (`Nunito-ExtraBold`), **Black** (`Nunito-Black`). There is no SF Pro anywhere (SF Symbols icons stay).

Every style is `Font.custom(name, size:, relativeTo:)` mapped to the same Dynamic Type text style as before, so it **grows with the iPhone's text-size setting**. Numbers that change get `.monospacedDigit()`. Exposed as `Font.app.<name>`.

| Name | Weight | Size, relative to | Used for |
|---|---|---|---|
| `screenTitle` | ExtraBold | 28, `.title` | "Today", "Streaks", "Settings", task name on the task screen |
| `successTitle` | ExtraBold | 22, `.title2` | "Gym done" |
| `statValue` | Black, monospaced digits | 20, `.title3` | "3w 2d", "1 of 1", the streak on the hero card |
| `cardTitle` | Bold | 17, `.headline` | Task name on a card, dialog title, form screen title |
| `cardStreak` | Black, monospaced digits | 17, `.headline` | The streak on the right of a task card |
| `statusCount` | Black, monospaced digits | 15, `.subheadline` | The "2 of 3" count in Today's status line |
| `weekStripNumber` | Black, monospaced digits | 15, `.subheadline` | Date numbers in the week strip |
| `celebrationNumber` | Black, monospaced digits | 64, fixed | The big streak number on the celebration |
| `dayStreakNumber` | Black, monospaced digits | 44, `.largeTitle` | The day streak in Today's header (in `flame`) |
| `dayStreakLabel` | Bold, ALL CAPS, 0.8pt tracking | 13, `.footnote` | "DAY STREAK" under it, "GYM STREAK" on the celebration |
| `button` | ExtraBold, ALL CAPS, 0.8pt tracking | 15, `.subheadline` | All button labels ("CHECK IN", "USE A SKIP") |
| `body` | SemiBold | 17, `.body` | Form field text, list rows |
| `subhead` | SemiBold | 15, `.subheadline` | Date line, dialog body, empty-state body |
| `meta` | SemiBold | 13, `.footnote` | Card meta line, helper text, schedule line |
| `sectionHeader` | ExtraBold | 13, `.footnote` | "Today", "Coming up", "This week", "Recent check-ins" |
| `pill` | Bold, ALL CAPS, 0.8pt tracking | 12, `.caption` | Status pills ("DONE 7:42 AM", "OPENS 9:00 PM") |
| `caption` | SemiBold | 12, `.caption` | Stat tile labels, field labels, day letters, photo dates |
| `badgeIcon` | — | 20, fixed | The icon in an `IconBadge` and the icon picker |
| `settingsIcon` | — | 15, fixed | The icon in a Settings row's 28pt badge |
| `tabIcon`, `largeIcon`, `celebrationIcon` | — | as before | SF Symbol sizes |

- **ALL CAPS + 0.8pt letter spacing** (`Typography.capsTracking`) for every **button label** and **status pill**. Only the display is uppercased: the strings stay in sentence case in `Strings`, and VoiceOver reads them in sentence case.
- Section headers stay sentence case.

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

### 1.4 Corner radius — `DesignSystem/Radius.swift`

Continuous corners everywhere.

| Name | Value | Used for |
|---|---|---|
| `sm` | 8 | Photo thumbnails |
| `md` | 12 | Icon badges, form fields, stat tiles, icon cells, the selected tab's square |
| `lg` | 16 | **Chunky buttons and chunky cards** (incl. the hero card) |
| `xl` | 20 | Dialog card |
| `full` | capsule / circle | Chips, day chips, week-strip circles, progress bars |

### 1.5 Sizes, lines, and depth

- **Chunky buttons:** 52pt tall (the face), plus a 4pt lip under it.
- **Chunky cards:** 2pt `border` outline plus a 5pt lip along the bottom.
- **Pressing:** buttons move down 4pt and their lip disappears; tappable cards move down 3pt. About 0.08s.
- **Tap targets:** at least 44×44pt everywhere.
- **Progress bars:** 16pt tall, fully rounded, `track` behind, colored fill, and a 4pt `highlight` stripe along the top of the fill (inset from the ends), like a glossy candy bar. `ProgressBar` component; nothing on screen uses one yet (the rings in the week strip stay rings).
- **Week strip:** 36pt circles, 3pt rings.
- **Tab bar:** 64pt tall plus the bottom safe area, 2pt `border` line on top.
- **Shadows and gradients:** none.
- **Icons:** SF Symbols only.

### 1.6 Motion, haptics, and sound

**Motion** (`DesignSystem/Motion.swift`, SwiftUI only):

- **First appearance of a screen:** its cards slide up 12pt and fade in, staggered 40ms apart (only the first ~10 are staggered). Not repeated when you come back to a screen that's already been shown.
- **Changing numbers** (streaks, counts, the status line count, stat tiles, "Done today · n") use `.contentTransition(.numericText())`.
- **Task card state changes** (e.g. open → done) animate with a spring, not a snap.
- **Celebration** (now a sequence of steps, section 4.8): the flame pops in (0.5 → 1.0, spring), then does a quick happy **wiggle**; a **confetti burst** of 50 small particles in the bright colors shoots up from behind the flame and falls with gravity over about 1.5s (drawn with `Canvas` + `TimelineView`). The number counts up. It closes on its own after 2.5s.
- **Chunky press:** down 4pt (cards 3pt) over ~0.08s, back up on release.
- **Reduce Motion on** (or Settings → Celebration animation off for the celebration): no confetti, no wiggle, no pop, no count-up, no slide-ins, no press movement — content just appears.

**Haptics** (all off when Settings → Vibrations is off):

- **Light** on every chunky button press.
- **Success** on a check-in.
- **Warning** on using a skip.
- **Soft** on toggles and pickers (Settings toggles and pickers, day chips, the color and icon picker, the skips stepper).

**Sounds** (`Services/SoundPlayer.swift`; files in `Resources/Sounds/`, sources in `docs/credits.md`):

| Moment | Sound |
|---|---|
| Check-in submitted | `checkin` — a bright "ding" |
| Celebration appears | `celebration` — a short cheerful flourish (under 1.5s) |
| A skip is used | `skip` — a soft whoosh |
| A streak ends | `streakEnded` — a low, gentle "bloop" (played by the "day streak ended" screen; per-streak breaks will play it once the streak rules exist) |
| The flame reaches a new form | `evolution` — a slightly bigger, longer rising flourish (about 1s) |

- Nothing on regular button taps.
- **Ambient** audio session: the iPhone's silent switch mutes them, and they mix with music instead of stopping it.
- All five are **preloaded** at launch so they play without delay.
- **Settings → Sounds** (on by default) turns them all off.

---

## 2. Reusable components

Each in its own file under `Views/Components/`:

- **`ChunkyButton`** — replaces the old Primary / Secondary / DangerText buttons.
  - Face: `Radius.lg`, 52pt tall, full width unless side by side; label in `Font.app.button` (ALL CAPS, 0.8pt tracking), optional leading SF Symbol. Lip: 4pt of the lip color under the face.
  - **Pressed:** the face moves down 4pt and the lip disappears (~0.08s), with a **light haptic**.
  - Variants:
    - `primary`: `flame` fill, `flameLip` lip, `textOnBright` label
    - `success`: `success` fill, `successLip` lip, `textOnBright` label
    - `secondary`: `surface` fill, 2pt `border` outline, `border` lip, `info` label
    - `danger`: `surface` fill, 2pt `border` outline, `border` lip, `danger` label
    - `white(label:)`: `whiteButton` fill, `whiteButtonLip` lip, label in the given color (the hero card's Check in, in the streak's `main`)
    - `onDark`: white at 15% fill and lip, white label (photo preview's Retake, on black)
    - **disabled** (any variant): `disabled` fill, `disabledLip` lip, `textTertiary` label, no press
  - VoiceOver reads the title in sentence case.
- **`ChunkyCard`** (`.chunkyCard()` modifier, `ChunkyCardButtonStyle` for tappable cards)
  - `surface` fill, 2pt `border` outline, 5pt `border` lip along the bottom, `Radius.lg`. Tappable cards press down 3pt.
  - A custom fill and lip can be given (the hero card).
- **`StatusPill`** — no box: just `Font.app.pill` text (ALL CAPS, tracked) in the status color.
  - `open`: `flame`, "OPEN NOW"
  - `done(time)`: `success`, "DONE 7:42 AM"
  - `upcoming(time)`: `textTertiary`, "OPENS 9:00 PM"
  - `skipped`: `textSecondary`, "SKIPPED"
  - `missed`: `danger`, "MISSED"
- **`StreakLabel`** — `flame.fill` in `flame` followed by the formatted streak (section 3); `short` ("3w 2d") and `long` ("3 weeks 2 days") styles.
- **`TaskCard`** — a `ChunkyCard` (tappable, presses down). **Hero** (the open streak): filled with the streak's `main`, its `lip` as the 5pt bottom edge, no outline; all text in `textOnBright` (`onBrightMuted` for the meta line); the badge in its hero style; a `ChunkyButton(.white)` "CHECK IN" with the label in the streak's `main`. The hero card itself doesn't press down (its Check in button does).
- **`StatTile`** — `surfaceRaised` fill, 2pt `border`, `Radius.md`; label `caption` / `textSecondary`, value `statValue` / `textPrimary`.
- **`WeekDayCircle`** (task screen, "This week") — 32pt: `done` the streak's `main` with a `textOnBright` checkmark; `skipped` `surfaceMuted` with a `textSecondary` minus; `missed` `dangerSoft` with a `danger` xmark; `today` a 3pt `flame` ring with a `flame` dot; `upcoming` `surfaceMuted`.
- **`DayChip`** — 36pt circle, letter in `Font.app.cardTitle`. Selected: `flame` fill, `textOnBright` letter. Unselected: `surfaceMuted` fill, 2pt `border`, `textSecondary` letter. Soft haptic on tap.
- **`PhotoThumbnail`** — square, `Radius.sm`; placeholder `surfaceMuted` with a `photo` icon in `textTertiary`.
- **`EmptyStateView`** — the happy Ember, a speech bubble, and a chunky "CREATE A STREAK" button (section 4.2).
- **`FilterChip`** — capsule, label `Font.app.cardTitle`. Selected: the streak's `main` (or `flame` for "All") with a `textOnBright` label. Unselected: `surface` fill, 2pt `border`, `textPrimary` label.
- **`DisclosureRow`** — "Done today · 2" / "Archived · 1" in `meta` / `textSecondary` with a chevron, 44pt tall; the count animates.
- **`HabitRow`** — the Streaks tab card, a tappable `ChunkyCard` (section 4.10).
- **`AppDialog`** — centered over `scrim`: `surfaceRaised` card, 2pt `border`, `Radius.xl`; title, body, then two stacked `ChunkyButton`s. The **first is always the safe choice** as `.primary`; the second is the action, as `.secondary` (neutral) or `.danger` (destructive).
- **`PhotoViewer`** — one photo full screen on black with its date and a close button.
- **`IconBadge`** — 40pt square, `Radius.md` (12): the streak's `badge` (20%) fill, icon in its `main`. **On the hero card:** white at 25% (`heroBadge`) behind a `textOnBright` icon, so it stands out against the streak color. Decorative for VoiceOver.
- **`AppTabBar`** — section 4.0: `surface` background, 2pt `border` line on top. **Selected tab:** its icon sits in a `Radius.md` rounded square with a 2pt `info` border and `info` at 15% behind it; icon and label `info`. **Unselected:** `textTertiary`.
- **`WeekStrip`** — section 4.1: **completed** days are `flame` circles with a white `flame.fill` icon instead of the number; **today** is a `surfaceRaised` circle with its number in `flame` and a 3pt `flame` ring (the part not yet done at 35%, so it doubles as today's progress); **partly completed past days** are `surfaceMuted` with a 3pt `flame` ring proportional to progress over `track`; **future days and days with nothing scheduled** are `surfaceMuted` with the number in `textTertiary`. Past days are tappable.
- **`StreakStylePicker`** — 8 color swatches (32pt, the selected one ringed in `textPrimary`) and a 6-column icon grid (`Radius.md` cells; selected: the color's `badge` fill and `main` icon). Soft haptic on each pick.
- **`ProgressBar`** — 16pt, capsule, `track` behind, colored fill with the glossy `highlight` stripe. Shown in the Design Gallery; not used on a screen yet.
- **`ConfettiView`** — the celebration's particle burst (`Canvas` + `TimelineView`).
- **`StaggeredAppear`** (`.appearSlideIn(index:)` modifier) — the first-appearance slide-up and fade.

## 2b. The flame character — `Views/Flame/`

**`FlameCharacterView(form:mood:size:days:)`** — drawn with SwiftUI only (`Canvas` + `TimelineView`), no image files.

- **Body:** a rounded teardrop with 2–5 flame **tongues** on top (none for the Ember), a **lighter inner core** in its lower half, and a **3pt darker outline** around the whole shape. No gradients: every layer is a flat color.
- **Face**, on the lower half of the body: two white oval **eyes** with dark (`textOnBright`) pupils and a **mouth** below them.
- **Size:** the view is `size` × `size`. The body is drawn at the form's scale × about two thirds of `size`, standing on the bottom edge, so the biggest form (150%) fills the frame and smaller forms leave room. Glow, embers, and sparkles may spill past the frame.

**Forms** (by day streak; `FlameForm`, `Models/DayStreak.swift`):

| Form | Days | Scale | Look |
|---|---|---|---|
| Ember | 0 | 60% | `flameLip` body, `flame` core, no tongues (a plain teardrop), low glow |
| Spark | 1–6 | 75% | `flame` body, `flameSparkCore` core, 2 tongues |
| Flame | 7–13 | 100% | `flame` body, `gold` core, 3 tongues |
| Blaze | 14–29 | 110% | as Flame, 4 tongues, soft glow |
| Bonfire | 30–49 | 120% | 5 tongues, glow, embers floating up |
| Inferno | 50–99 | 130% | a `danger` outer layer, `flame` middle, white-hot core, bigger glow |
| Wildfire | 100–364 | 140% | as Inferno with `purple` tongue tips and twinkling sparkles |
| Eternal | 365+ | 150% | `info` body, white core and highlights, sparkles orbiting it |

The **glow** is two flat, translucent circles of the body color behind the flame (no blur, no gradient).

**Moods** (`FlameMood`; which one shows is decided in `context.md` §10):

| Mood | Eyes | Mouth | Extra |
|---|---|---|---|
| `happy` | white ovals, pupils | small smile | — |
| `proud` | happy arcs (∩) | big open smile | one more level of glow |
| `sleepy` | closed (gentle curves) | small "o" | a "z" floats up and fades every few seconds |
| `worried` | wide ovals, small pupils | wavy line | a blue (`info`) sweat drop |
| `sad` | droopy, half closed | frown | the whole flame dimmer |
| `cheering` | "^ ^" | wide open | bouncing (celebrations only) |

**Idle animation:** each tongue sways on its own offset sine wave; the body "breathes" between 98% and 102% over about 2 seconds; the eyes blink every 3–6 seconds at random. **Reduce Motion:** no sway, breathing, bouncing, floating, or orbiting (embers, sparkles, and the "z" hold still); blinking stays. Small copies (the Flame screen's form path, the Flame Lab grid) are drawn still (`animated: false`).

**VoiceOver:** one image, e.g. "Your flame. Blaze form. Happy. 23 day streak."

**`SpeechBubble(text:)`** — `surface` fill, 2pt `border` outline, `Radius.lg` (16), `Spacing.md` padding, text in `subhead` / `textPrimary`. A small pointer on its top edge points up at the flame (left-aligned under the flame in the Today header, centered elsewhere).

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

**Streak, short style:** "3w 2d", "1w 1d", "2d", "3w", and **"0"** for zero. On cards and tiles zero reads "0" in the days-only mode too, and the flame next to a zero streak is `textTertiary` (grey) instead of `flame`. (The long style on the celebration keeps "No streak yet".)

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

- `surface` background reaching into the bottom safe area, a 2pt `border` line along the top, 64pt tall plus the safe area.
- **Each tab:** a 22pt icon (`Font.app.tabIcon`) with its label in `caption` underneath. **Selected:** the icon sits inside a `Radius.md` rounded square with a 2pt `info` border and `info` at 15% behind it; icon and label in `info`. **Unselected:** `textTertiary`, no square. Each half of the bar is its tab's tap target.
- VoiceOver reads them as tabs, with the current one marked selected.

**Planned, not built:** a third **Friends** tab comes with shared folders. Then Today moves to the center as a raised round button. Nothing for it exists in this version.

### 4.1 Today tab — `Views/Home/HomeView.swift`

Top to bottom: header (top row, flame row, speech bubble) → "This week" row → week strip → status line → hero card(s) → Later today → Coming up. On a rest day there's no hero card and no Later today section.
**Header** (scrolls with the content, no navigation bar title, no big "Today" title any more):

- **Top row:** a **gear** button on the left (`gearshape`, `textSecondary`, 44pt tap target, VoiceOver "Settings") opens Settings as a sheet (section 4.13). A **+** button on the right (`plus`, `flame`, 44pt) opens Create Task. The middle stays empty (the rewards phase puts coins and XP there).
- **Flame row:** the flame (`FlameCharacterView`, about 96pt, in its current mood) on the left. On the right, `Spacing.md` away and stacked:
  - the **day streak** number in `dayStreakNumber` (Nunito Black, about 44pt) in `flame` (`textTertiary` when it's 0); it animates with `.numericText()` when it changes;
  - **"DAY STREAK"** in `dayStreakLabel` (Bold, ALL CAPS, 0.8 tracking) / `textSecondary`;
  - the greeting and short date in `meta` / `textTertiary`: "Good evening, Ajeeth · Thu, Oct 1" (greeting rules in section 3; ", {name}" only when a name is set).
- **Tapping the flame or the number** opens the Flame screen (section 4.14). VoiceOver reads them as one button: "Your flame. Blaze form. Happy. 23 day streak."
- **Speech bubble** (`SpeechBubble`), `Spacing.sm` below the flame row, full width, its pointer under the flame. One line, picked at random from the pool for the situation (first match wins); always kind:
  1. The day streak **ended today** and nothing is checked in since: "That's okay. One check-in brings me back."
  2. An open window **closes within 15 minutes**: "{Task} closes in {m} min! Quick, snap a photo!"
  3. A window is **open**: "{Task} is open — let's do this!" / "Time for {task}. I'm ready when you are."
  4. Only **later today** is left: "Next up: {task} at {time}."
  5. **Everything resolved** today: "All done today. I'm glowing!" / "That's everything. Proud of you."
  6. **Rest day**: "Rest day. Recharging for tomorrow."
  7. Nothing left today but something was missed (not in the brief; added so there's always a line): "That's it for today. See you next time!"

**"This week" row**, `Spacing.md` below the speech bubble: "This week" in `sectionHeader` / `textTertiary` on the left; on the right, **"History"** and a `chevron.right` in `meta` / `accentText`, with a 44pt tap target. Tapping it opens History (section 4.12).

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

- **"Later today":** the other tasks still ahead today (window opens later) — **sorted by window start time**. Open tasks aren't repeated here; they're the hero cards above. Hidden on a rest day, and when it would have no cards and no "Done today" row. A task that was **missed** today also stays here in its time-sorted spot, so its "Streak ended" lines stay visible.
- **"Done today" row**, at the bottom of the Today section: tasks **checked in or skipped** today collapse into one row, "Done today · 2" in `meta` / `textSecondary`, with a `chevron.down` (collapsed) or `chevron.up` (expanded) on the right. Tapping it shows or hides their compact cards (done and skipped states below), in window order. It starts collapsed; whether it's open is remembered until the app closes. Hidden when nothing is done or skipped. If nothing is ahead or missed either, the Today section shows only this row.
- **"Coming up":** one row per task **not scheduled today**, sorted by its next window (soonest first). Hide this section if it's empty. Each row: `surface` fill, `Radius.lg`, `Spacing.md` padding, 0.5pt `separator` outline; the streak's `IconBadge`, then its name in `cardTitle` / `textPrimary` on the left; the next window's day and start time on the right in `meta` / `textSecondary` ("Tomorrow, 9:00 PM", "Sunday, 10:00 AM"). VoiceOver reads "Guitar · Tomorrow, 9:00 PM". Tapping it opens the task screen.

Cards and rows are separated by `Spacing.sm`. **Tapping anywhere on a card** (other than its button) opens that task's screen.

**Hero card** (the open task: window open, not checked in or skipped):

- A chunky card filled with the streak's `main`, with its `lip` as the 5pt bottom edge. `Radius.lg`, `Spacing.md` padding, no outline. All text and icons on it are `textOnBright` (the meta line `onBrightMuted`). The streak number may be white only at 20pt bold or larger; it uses `textOnBright` like everything else.
- Title row: the `IconBadge` in its hero style on the left, `Spacing.sm` before the task name (`cardTitle`); on the right, the `flame.fill` icon and the streak (`statValue`), both `onAccent`. The streak follows Settings → Show streaks as.
- `xxs` below: "Closes in 1h 20m · 1 skip left" in `meta` / `onAccentMuted`. The countdown updates every minute; under an hour it reads "Closes in 12m".
- `Spacing.sm` below: a full-width **inverted** `PrimaryButton` "Check in" with `camera.fill`: `onAccent` (white) fill, label and icon in the streak's `solid` color. **No skip button here.**

**Other `TaskCard` states.** `surface` fill, `Radius.lg`, `Spacing.md` padding, 0.5pt `separator` outline.

- **Title row:** the task name (`cardTitle`) on the left; on the right, the `flame.fill` icon (`streak` color) and the streak in `cardStreak`, short or days-only following the owner's toggle. The streak's `IconBadge` sits on the left of the whole card, `Spacing.sm` before the name and status rows.
- **Status row** (`xxs` below the title): the `StatusPill` text, then **" · "** (`textTertiary`), then the meta line in `meta` / `textSecondary`, as one line that wraps: "OPENS 9:00 PM · 1 skip left", "DONE 7:42 AM · Next: Tomorrow". With no meta, just the pill.

| State | Pill | Meta line | Notes |
|---|---|---|---|
| **Done** | `done` "DONE 6:42 PM" | "Next: Friday" | Task name and streak in `textSecondary`. Shown inside the expanded "Done today" row. |
| **Upcoming** (later today) | `upcoming` "Opens 9:00 PM" | "2 skips left" | — |
| **Skipped today** | `skipped` | "No skips left" | Shown inside the expanded "Done today" row. |
| **Missed today** | `missed` | — | Streak-ended lines (below) |

A done task can't be checked in again until its next scheduled window. On the task screen its Check in button stays disabled and reads "Done today".

**Streak-ended lines** (shown on a card after a streak breaks), stacked below the status row with `xxs` spacing:

- Line 1, `meta` / `danger`: "Streak ended **today** at 3w 3d" if the miss was today, "Streak ended **yesterday** at 3w 3d" if yesterday, otherwise "Streak ended **Friday** at 3w 3d".
- Line 2, `meta` / `textSecondary`: "Longest: 5w 1d · Starts fresh today" **only** if today is a scheduled day whose window hasn't closed yet; otherwise "Longest: 5w 1d · Next try: Tomorrow" (or the weekday of the next scheduled day, e.g. "Next try: Saturday").
- How long these stay visible is **(open)**. For now, show them until the next check-in on that task.

### 4.2 Home, empty state — `Views/Components/EmptyStateView.swift`

Shown when there are no active streaks at all. Only the header's top row stays (gear and +); the flame row, speech bubble, "This week" row, week strip, and status line are hidden. The rest is centered vertically and horizontally:

- The **Ember** in its happy mood, about 120pt.
- `Spacing.sm` below: a `SpeechBubble` (pointer up, centered): "Hi! I'm your flame. Create a streak and help me grow."
- `Spacing.xl` below: a chunky primary button **"CREATE A STREAK"** (`ChunkyButton(.primary)`, `plus` icon) that opens Create Task.

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
- If the window has closed by the time the photo is submitted, the check-in isn't saved and the camera screen shows "The window closed at 8:00 PM." with only the close button.
- **Camera access off:** "Camera access is off. Turn it on in Settings to check in with a photo." with an "Open Settings" button (`onDark`). The shutter and switch buttons are dimmed until the camera runs.
- **The iPhone simulator has no camera.** In DEBUG builds running on the simulator, show a "Use sample photo" button in place of the live view.

### 4.7 Photo preview — `Views/CheckIn/PhotoPreviewView.swift`

- Black background, the captured photo fitted to the screen.
- Top: "Gym · closes 8:00 PM" in `subhead`, white.
- Bottom: `SecondaryButton` "Retake" and `PrimaryButton` "Submit", side by side, equal width, `xs` gap, `Spacing.lg` from the bottom safe area. On this screen only, "Retake" has a translucent white fill (white at 15%) and a white label, so it reads on black.

### 4.8 Celebration sequence — `Views/CheckIn/StreakCelebrationView.swift`, `Views/Flame/FlameCelebrationSteps.swift`

Shown full screen right after Submit, on `background`. Up to **three steps**, one after another (the screen stays; only the content changes):

**Step 1 — the check-in (always).**

- The flame (the current form, **cheering**, about 150pt) pops in (0.5 → 1.0, spring) in front of a flat disc of the streak's `badge` color (about 280pt), with the confetti burst, the **success haptic**, and the `celebration` sound (just after the check-in ding).
- Below it, the **streak's own count** in `celebrationNumber` / `textPrimary`, counting up (12 → 13), always in days.
- Under the number: **"GYM STREAK"** ("{Task} streak", ALL CAPS, `dayStreakLabel`) in the streak's `main` color.
- `Spacing.lg` below: "{Task} done" in `successTitle`; `xxs` below, the week line in `meta` / `textTertiary` ("1 more to finish the week", "Week complete", plus "Your skip is back — 1 skip left" when a skip was given back).
- **If it's the only step:** closes on its own after **2.5s**; tapping anywhere closes it sooner. **If more steps follow:** moves on after **2s**; tapping moves on sooner.

**Step 2 — the day streak (only if this check-in completed the day).**

- The flame (the new day streak's form, cheering) **hops** when the number lands.
- **"DAY STREAK"** in `dayStreakLabel` / `textSecondary` over the day streak in `celebrationNumber` / `flame`, counting up (22 → 23).
- **Milestone checkpoint bar**: three nodes joined by a 6pt track. Left: the last milestone reached (a `flame` circle with a white checkmark, the form's name under it). Middle: today's spot, a bigger `flame` circle with the day number and a soft glow ring. Right: the next milestone, dim (`surfaceMuted` circle with its day count in `textTertiary`, the form's name under it). The left half of the track is `flame`, the right half `track`. At Eternal there's no right node.
- Under it in `subhead` / `textSecondary`: "7 days to Bonfire" (or "You've reached the final form.").
- **After a break**, the first completed day says **"Your flame is back!"** (`screenTitle`) above, and the flame grows from Ember into Spark (0 → 1).
- A chunky primary **"CONTINUE"** button at the bottom. It moves to step 3, or closes.

**Step 3 — a new form (only if the flame just reached one; not for Ember → Spark, which step 2 shows).**

- The old form shrinks, a white flash fills the screen for about 0.2s, then the new form bursts in larger with a second, bigger confetti burst and the `evolution` sound.
- "Your flame became a Blaze!" in `screenTitle`, then a one-line description of the new look in `subhead` / `textSecondary` (section 6).
- A chunky primary **"CONTINUE"** button closes it.

**Reduce Motion, or Settings → Celebration animation off:** no pop, hop, flash, confetti, or count-up — each step shows its final values straight away. Timings and buttons stay the same.

VoiceOver reads each step as one element ("13. Gym streak. Gym done. 1 more to finish the week."); the CONTINUE button is separate.

**Closing the task.** Back on the Today tab, the hero card animates into the "Done today" row, the week strip ring fills, and the header's day streak and flame update.

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

Every group is a **chunky card** (`SettingsSection`: `surface` fill, 2pt `border`, 5pt bottom lip, `Radius.lg`) with its header above in `sectionHeader` / `textTertiary` and an optional footer below in `meta` / `textSecondary`. Rows are 52pt tall with 1pt `border` lines between them (starting after the icon). Title: "Settings" in `screenTitle` above the groups (scrolls with them). Everything here is saved on the device.

**Each row** (`SettingsRow`) starts with a **28pt rounded-square icon badge** (`Radius.sm`, bright fill, icon in `textOnBright`), then the label in `body` / `textPrimary` (long labels wrap), then its control or value on the right:

| Row | Icon | Badge color |
|---|---|---|
| Your name | `person.fill` | `purple` |
| Show streaks as | `flame.fill` | `flame` (orange) |
| Repeat during window | `bell.fill` | `info` (blue) |
| Last-call warning | `alarm.fill` | coral |
| Vibrations | `iphone.radiowaves.left.and.right` | `success` (green) |
| Sounds | `speaker.wave.2.fill` | teal |
| Celebration animation | `sparkles` | `gold` (yellow) |
| Archived streaks | `archivebox.fill` | `purple` |
| Photo storage | `photo.fill` | `info` (blue) |
| Delete all data | `trash.fill` | `danger` (label in `danger` too) |
| Version | `info.circle.fill` | `textTertiary` (grey) |
| Design Gallery (DEBUG) | `paintbrush.fill` | `textTertiary` (grey) |

- Choices (Show streaks as, Repeat during window, Last-call warning) show the current value in `cardTitle` / `flame` with a `chevron.up.chevron.down`; tapping opens Apple's standard menu of options.
- Toggles are tinted `success`. Values (photo storage, version, archived count) are `body` / `textSecondary`; rows that open a screen end with a `chevron.right`.
- The notifications-off warning is the first row of the Reminders card, on `dangerSoft`.

**You** (the first section)
- "Your name" on the left in `body` / `textPrimary`; a text field on the right, right-aligned, placeholder "Optional", in `body` / `textSecondary`. Up to 30 characters; leading and trailing spaces are trimmed. Saved on the device.
- Footer: "Only used for your greeting. It stays on this iPhone."

**Display**
- "Show streaks as" → "Weeks and days" (default) / "Days only". This is the only weeks/days switch in the app.

**Reminders**
- Only when iPhone notifications are turned off for this app (denied in the iPhone's Settings): a warning row first, `dangerSoft` background, `exclamationmark.triangle.fill` in `danger`, "Notifications are off. Your streaks can end without a warning." in `subhead` / `textPrimary`, and a "Turn on" button in `accentText` that opens this app's page in the iPhone Settings app.
- "Repeat during window" → "Every 10 min" / "Every 15 min" (default) / "Every 30 min".
- "Last-call warning" → "10 min before" / "15 min before" (default) / "30 min before".
- Footer: "Reminders are always on for every streak. They stop as soon as you check in or use a skip."

**Feel**
- "Vibrations" → toggle, on by default. Off turns off every haptic.
- "Sounds" → toggle, on by default. Off silences every sound effect (section 1.6). The iPhone's silent switch also mutes them.
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
- Above it (DEBUG only), the developer tools (context.md §11): the current time on top ("Pretend time: Thursday, October 8 · 6:40 PM" in `flame`, or "Real time: …" in `textPrimary`); a row of four small buttons "+15 min", "+1 hour", "+1 day", "+1 week" (`pill` text in `info` on `surfaceRaised`); then rows "Reset to real time", "Fill with sample data", "Erase everything" (with an `AppDialog` confirmation), "Send test reminder in 5 seconds", and "Show pending reminders" (pushes a plain list of every scheduled reminder: its time, title, and body).
- **Pretend-time banner** (DEBUG only, `Views/Components/PretendTimeBanner.swift`): while the pretend clock is on, a 20pt full-width strip across the top of every screen, in its own window above sheets and full-screen covers, just under the status bar and Dynamic Island (above the gear and +): `gold` fill, `textOnBright` text in `pill` reading "Pretend time: Thu 8:01 PM · TAP TO RESET". Tapping it resets to real time.

### 4.14 Flame screen — `Views/Flame/FlameView.swift`

Pushed from the Today header (back button "< Today"; the tab bar hides, like History). Inline title "Your flame". Scrolls. Centered, top to bottom:

- The flame at about **200pt** in its current mood (animated).
- `Spacing.md` below: the form name ("Blaze") in `screenTitle`, then "23 day streak" in `subhead` / `textSecondary`.
- `Spacing.lg` below: the candy `ProgressBar` (`flame`) toward the next form, then "7 days to Bonfire" in `meta` / `textSecondary`. At Eternal the bar is full and the line reads "You've reached the final form."
- **Form path** (section header "Forms"): a horizontal scroll of all 8 forms, each a column with a small still character (56pt), its name in `caption` and its required days ("30 days"):
  - **reached** (below the current form): full color;
  - **current:** inside a 3pt `flame` ring;
  - **locked:** a `surfaceMuted` (`#26363E`) silhouette with a `lock.fill` icon, name in `textTertiary`.
  It starts scrolled to the current form.
- Two `ChunkyCard` stats side by side: **"Longest"** ("30 days") and **"Best form"** ("Bonfire").
- Bottom: just padding (the rewards phase adds the wardrobe here; no placeholder).

### 4.15 Day streak ended — `Views/Flame/DayStreakEndedView.swift`

Full screen, shown **once per break**, the first time the app is opened (or comes back) after the day streak ends. Centered on `background`:

- The **sad Ember**, about 160pt.
- "Your 23-day streak ended" in `screenTitle`.
- "Longest: 30 days · Best form: Bonfire" in `subhead` / `textSecondary`.
- A `SpeechBubble`: "One check-in brings me back."
- At the bottom: a chunky primary **"LET'S GO"** button that closes it.
- Plays the `streakEnded` bloop when it appears.

### 4.16 Flame Lab (Design Gallery, DEBUG only)

Gallery → Flame → **Flame Lab**: chips to pick a **form** (8) and a **mood** (6) with the live character at 200pt; buttons to play **each celebration step**, the **full 3-step** sequence, a **revival**, the **evolution** from the picked form to the next, and the **streak-ended screen**; and a still grid of **every form × every mood**. The section also has the Today header in each speech-bubble situation, the Flame screen, the ended screen, and the empty state.

---

### 4.17 Reminder permission — `Views/Reminders/ReminderPermissionView.swift`

Shown once, as a sheet, right after the first streak is created (context.md §7), only if reminders aren't already allowed. Centered on `background`:

- The **happy flame** (the current form; Ember for a brand-new user), about 120pt.
- `Spacing.sm` below: a `SpeechBubble` (centered): "I'll remind you when your windows open, so your streak never sneaks away."
- At the bottom: a chunky primary **"TURN ON REMINDERS"** button (`bell.fill`). It shows the iPhone's permission prompt (or, if reminders were turned off before, opens the app's page in the iPhone Settings app), then closes the sheet.
- Under it, a small plain **"Not now"** text button (`subhead`, `textSecondary`, 44pt tap target) that just closes it.
- No rewards or pressure for allowing.

### 4.18 Reminders (notifications)

Standard iPhone notifications with the app icon. Kind, never guilt-tripping (copy in §6). Repeats show the time left like the hero card ("1h 20m", "45m"). Last-call warnings are "time sensitive" where allowed.

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
| Section headers | Later today · Coming up · This week · Recent check-ins |
| Empty state | Hi! I'm your flame. Create a streak and help me grow. · Create a streak |
| Pills (shown ALL CAPS) | Open now · Done {time} · Opens {time} · Skipped · Missed |
| Buttons | Every button label is shown ALL CAPS with 0.8pt letter spacing ("CHECK IN", "USE A SKIP"); the text below is how it's written and how VoiceOver reads it. |
| Today status line | {n} of {m} done today · All done for today · Rest day · Next: {task} at {time} · Next: {task} tomorrow at {time} · Next: {task} {weekday} at {time} · {task} is open now |
| This week row | This week · History |
| Hero card | Closes in {h}h {m}m · Closes in {h}h · Closes in {m}m · Check in |
| Card meta | {status} · Next: {day} · {status} · {n} skips left |
| Zero streak | 0 |
| Streak ended | Streak ended today at {short streak} · Streak ended yesterday at {short streak} · Streak ended {weekday} at {short streak} / Longest: {short streak} · Starts fresh today · Longest: {short streak} · Next try: {Tomorrow or weekday} |
| Form | New streak · Edit streak · Cancel · Name · Color and icon · Which days · Time window · From · To · Skips per week · Create streak · Save changes |
| Form errors | End time must be after start time. |
| Next-week note | Starting next week: {n} skips (this week: {m}) |
| Task screen | Edit · Streak · Skips left this week · Longest: {streak} · Check in · Use a skip · See all · No check-ins yet. |
| Disabled buttons | Opens {time} · Closed · Done today · No skips left |
| Skip dialog | Use your last skip? · Use a skip? · Keep my skip · Use skip |
| Camera | {Task} · closes {time} · The window closed at {time}. · Use sample photo |
| Preview | Retake · Submit |
| Celebration | {days} · {Task} streak · {Task} done · {n} more to finish the week · Week complete · Your skip is back — {n} skip left · Day streak · Your flame is back! · {n} days to {form} · 1 day to {form} · You've reached the final form. · Your flame became a {form}! · Continue |
| History | {Task} History · No check-ins yet. Your photos will show up here. |
| Tab bar | Today · Streaks |
| Today header | Settings (VoiceOver, gear) · Create streak (VoiceOver, +) · Good morning · Good afternoon · Good evening · , {name} · {greeting} · {Thu, Oct 1} · Day streak · Opens your flame (VoiceOver hint) |
| Week strip (VoiceOver) | {weekday}, all done. Opens history. · {weekday}, {n} of {m} done. Opens history. · {weekday}, nothing scheduled. Opens history. · {weekday}, today, {n} of {m} done · {weekday} |
| History screen | History · Nothing scheduled · No check-ins |
| Colors (VoiceOver) | Coral · Orange · Green · Teal · Blue · Indigo · Pink · Purple |
| Icons (VoiceOver) | Dumbbell · Running · Walking · Bicycle · Drop · Sparkles · Book · Pencil · Brain · Guitar · Music · Paintbrush · Fork and knife · Cup · Leaf · Bed · Moon · Sun · Heart · First aid · House · Cart · Laptop · Star |
| Today tab | Coming up · Done today · {n} · {day}, {time} |
| Streaks tab | Streaks · Active · Archived · {n} · Not today · Best: {streak} |
| Archived streak | Archived · Best streak · Photos · Restore · Delete permanently |
| History tab | History · All · Today · Yesterday · Skipped {Task} · Missed {Task} · Missed {Task} · streak ended at {streak} · No check-ins yet. Your photos will show up here. |
| Settings | Settings · You · Your name · Optional · Only used for your greeting. It stays on this iPhone. · Display · Show streaks as · Weeks and days · Days only · Reminders · Notifications are off. Your streaks can end without a warning. · Turn on · Repeat during window · Every 10 min · Every 15 min · Every 30 min · Last-call warning · 10 min before · 15 min before · 30 min before · Reminders are always on for every streak. They stop as soon as you check in or use a skip. · Feel · Vibrations · Sounds · Celebration animation · Streaks · Archived streaks · No archived streaks. · Your data · Photo storage · {n} photos · {size} · No photos · Delete all data · Everything stays on this iPhone. Nothing is uploaded. · About · Version · Developer · Design Gallery · Done |
| Edit streak | Archive streak · Delete streak |
| Archive dialog | Archive {Task}? · It'll stop reminding you and leave your Today screen. Your photos and best streak are kept, and you can restore it anytime from Settings. · Cancel · Archive |
| Delete dialog | Delete {Task}? · This permanently deletes the streak and all its photos. · Cancel · Delete |
| Speech bubble | That's okay. One check-in brings me back. · {Task} closes in {m} min! Quick, snap a photo! · {Task} is open — let's do this! · Time for {task}. I'm ready when you are. · Next up: {task} at {time}. · All done today. I'm glowing! · That's everything. Proud of you. · Rest day. Recharging for tomorrow. · That's it for today. See you next time! |
| Flame forms | Ember · Spark · Flame · Blaze · Bonfire · Inferno · Wildfire · Eternal |
| Form descriptions (step 3) | Spark: A tiny spark with two flickering tongues. · Flame: Taller, with a bright golden core. · Blaze: Bigger, with four tongues and a soft glow. · Bonfire: Five tongues, a warm glow, and embers floating up. · Inferno: Red-hot edges and a white-hot core. · Wildfire: Purple-tipped tongues and sparkles all around. · Eternal: Blue and white, with sparkles in orbit. · Ember: A small, warm ember. |
| Moods (VoiceOver) | Happy · Proud · Sleepy · Worried · Sad · Cheering |
| Flame (VoiceOver) | Your flame. {Form} form. {Mood}. {n} day streak. |
| Flame screen | Your flame · {n} day streak · {n} days to {form} · You've reached the final form. · Forms · {n} days · Locked · Longest · Best form |
| Day streak ended | Your {n}-day streak ended · Longest: {n} days · Best form: {form} · One check-in brings me back. · Let's go |
| Reminders | Opens: {Task} is open / Until {end time}. Snap a photo to keep your streak going. · Repeat: {Task} · {time left} left / Your window closes at {end time}. · Last call: {Task} closes at {end time} / Check in or use a skip ({n} left). · Last call, no skips: {Task} closes at {end time} / Last chance to keep your {n}-day streak. · Last call, no streak yet: {Task} closes at {end time} / Last chance to check in today. · Safety net (title only, after the last scheduled reminder): Open the app so I can keep reminding you. |
| Reminder permission | I'll remind you when your windows open, so your streak never sneaks away. · Turn on reminders · Not now |
| Developer (DEBUG) | Pretend time: {time} · Real time: {time} · +15 min · +1 hour · +1 day · +1 week · Reset to real time · Fill with sample data · Erase everything · Send test reminder in 5 seconds · Show pending reminders · Pretend time: {Thu 8:01 PM} · TAP TO RESET |
| Delete-all dialogs | Delete everything? · All streaks and photos will be permanently deleted from this iPhone. · Cancel · Continue · This can't be undone. · Delete everything |
