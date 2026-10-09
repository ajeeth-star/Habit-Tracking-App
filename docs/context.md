# Habit App — Product Context

This is the product reference for the project. When something here conflicts with older notes (including `docs/background.md`, the original concept handoff), **this file wins**. When a product question comes up that this file doesn't answer, stop and ask the owner instead of guessing.

Status: v1 is being built in phases (list at the end). Data is saved on the iPhone; reminders and rewards aren't built yet. Version one (v1) scope is defined below.

---

## 1. The idea

A private iPhone app for building habits. You create tasks (gym, morning skincare, guitar), each with scheduled days and a daily time window, and you prove you did each one by taking a photo during that window. Streaks track how consistent you've been, and a small weekly allowance of skips lets you miss a day on purpose without losing your streak.

**Why:** it started with a gym group chat where friends kept each other going ("yo, you going gym?") by showing up and sending pictures. The long-term goal is that kind of accountability. v1 is the personal version: the check-in, the streak, and the daily pressure of deciding whether to go or burn a skip.

The single most important moment the app has to get right: **6 PM on a Thursday, you're busy, and you're deciding whether to use your last skip.**

## 2. Who uses it

- **v1: just the owner.** No accounts, no logins, no other users.
- **Someday: friends.** The planned model is shared "folders," like a shared photo album where everyone drops their own check-ins for a habit such as gym. Private habits (skincare) stay private.
- **Don't build folders, sharing, or user accounts yet.** But don't design anything in a way that makes adding them later painful.

## 3. What a habit (task) looks like

**On screen, each habit is called a "streak"** ("New streak", "Archive streak", the Streaks tab). In the code and in these docs it's still a task or habit.

Each task has:

- **A name**, e.g. "Gym".
- **A color and an icon**, picked on the create screen from 8 colors and a set of icons. A new streak starts with the next color not already in use and an icon guessed from its name (it can be changed). The color marks the streak everywhere it appears; the app's own purple stays for app-wide controls.- **Scheduled days**: any set of weekdays, e.g. Mon, Tue, Thu, Fri.
- **One time window per day**, e.g. 6:00–8:00 PM. The same window applies to every scheduled day. Multiple windows per day are out of v1.
- **Skips per week**, chosen by the user. Any number from 0 up to the number of scheduled days, with no stricter cap (see streak rules for why that's safe).

Tasks are fully independent. Each has its own schedule, skips, streak, and history.

All fields are set on **one create screen**. Under the skips counter, a plain-language line explains the choice, e.g. "You can miss 1 of your 4 gym days each week and keep your streak." It updates live.

**Editing a task:**

- Name and time window: changes take effect **immediately**.
- Scheduled days and skip count: changes take effect **next Monday**. The screen says so, e.g. "Starting next week: 2 skips (this week: 1)." This stops users from rescuing a streak by editing mid-week.

**Weeks start Monday** for every task. Skips refill every Monday and don't carry over. A task created mid-week gets its full skip allowance for that first partial week.

## 4. Completing a habit

**A photo is always required.** There is no photo-less check-in in v1.

- **In-app camera only.** No choosing photos from the camera roll, which prevents reusing an old photo.
- **Only during the window.** Before the window opens, the check-in button is disabled with the opening time, e.g. "Opens 6:00 PM". After it closes, check-in is no longer possible for that day. This rule must live in **one clearly named place in the code**, because the owner may loosen it later.
- **Preview before it counts.** After taking the photo, show it with **Retake** and **Submit**.
- **Any photo is accepted in v1.** Smart photo checking (on-device Apple Vision first, maybe an AI service later) is a future phase. Don't build it yet.
- **Photos are kept on the device** and shown in that task's check-in history, each with its date and time. Save them compressed so storage doesn't balloon; hundreds of photos a year is expected.
- **After submitting:** a confirmation showing "Gym done", the updated streak, and progress for the week, e.g. "1 more to finish the week". Decided: a full-screen streak celebration that closes on its own after 2.5 seconds (tap to close sooner), then the task shows as done on Home (see `docs/design.md` §4.8).

**Using a skip:**

- A skip is used **from inside the task's screen**, never from the home screen. The extra step is intentional.
- It can be used any time on a scheduled day, before or during the window.
- It always requires a **confirmation** that shows how many skips remain and states the real consequence, e.g.
  > **Use your last skip?** You have 2 gym days left this week. If you skip today, you'll have to make it Friday to keep your streak.
- In the confirmation, the **highlighted button is "Keep my skip"**. "Use skip" is the secondary option. The design nudges toward going.
- **Checking in after using a skip refunds the skip**, if you end up going while the window is still open.

## 5. The screens

The app has a **tab bar with two tabs: Today (left) and Streaks (right).** The app always opens on Today. Each tab keeps its own back-and-forth navigation, so going back never jumps to another tab. **Settings** opens from a gear button at the top left of Today. **History** opens from Today (a "History" link above the week strip, or by tapping a past day).

**Planned, not built:** a third **Friends** tab arrives with shared folders. At that point Today moves back to the center as a raised round button. Nothing is built for it now.

**Today tab (the hub)**

- A greeting ("Good morning", "Good afternoon", "Good evening") above the title, followed by the owner's name if one is set in Settings ("Good evening, Ajeeth").
- A "This week" row with a **History** link on the right.
- A Monday–Sunday strip for the current week: each past day shows how much of what was scheduled got done, today shows its progress so far. Tapping a past day opens History at that day.
- **One status line** under the strip: how many of today's tasks are checked in and what's next ("2 of 3 done today · Next: Gym at 6:00 PM", "2 of 3 done today · Gym is open now", "All done for today · Next: Guitar tomorrow at 9:00 PM").
- The task whose **window is open** comes right after the status line as the highlighted hero card with **a single "Check in" button**. No skip button here.
- **Today**: the other tasks still ahead today, plus any missed today, **sorted by window start time**.
- Tasks **checked in or skipped today** collapse into one row at the bottom of the Today section ("Done today · 2"). Tapping it shows or hides them. Whether it's open is remembered until the app closes.
- **Coming up**: every task not scheduled today, with its next window, sorted by soonest, e.g. "Guitar · Tomorrow, 9:00 PM".
- **Rest day** (streaks exist, none scheduled today): the status line reads "Rest day · Next: Gym tomorrow at 6:00 PM" (or "… Gym Friday at 6:00 PM"); no Today section or hero card; the week strip and Coming up show as normal.
- Each task shows its status (open now / done with the check-in time / opens at a time) and its streak.
- A **+** button creates a task.
- **Empty state (no streaks at all):** the happy Ember says "Hi! I'm your flame. Create a streak and help me grow." above a "Create a streak" button (design.md §4.2). This is what a fresh install shows. No week strip, History link, or status line. No intro or onboarding screens.

**Streaks tab**

- Every active habit, sorted by current streak (highest first), with its schedule, today's status, current streak, and best streak. Tapping one opens its task screen.
- **Archived** habits in a collapsed section at the bottom. Opening one offers **Restore** and **Delete permanently**.
- A + button creates a task.

**History** (pushed from Today; the tab bar hides while it's open)

- Opened with the "History" link on Today, or by tapping a past day in the week strip (it then opens scrolled to that day). A standard back button returns to Today, and swiping from the left edge does too.
- Every check-in photo across all habits, newest first, grouped by day ("Today", "Yesterday", "Thursday, Sep 24"), with filter chips for one habit at a time.
- Skips and misses show as small text lines without a photo.
- The per-task history (from "See all" on a task screen) stays as it is.

**Settings** (a sheet from the gear on Today, with a Done button)

- **You:** an optional name, used only for the greeting on Today. Stays on the iPhone.
- **Display:** show streaks as weeks and days (default) or days only. The app is always dark; there's no appearance setting.
- **Reminders:** repeat during the window every 10, 15 (default), or 30 minutes; last-call warning 10, 15 (default), or 30 minutes before the window closes. If iPhone notifications are off for the app, a warning with a button to the app's page in the iPhone Settings app.
- **Feel:** vibrations on/off (all haptics); sounds on/off (short effects for check-in, celebration, skip, streak ending; the iPhone's silent switch mutes them); celebration animation on/off.
- **Streaks:** the archived streaks list.
- **Your data:** how many photos are stored and how much space they take; **Delete all data** (two confirmations).
- **About:** app version.
- Settings are saved on the device and remembered after the app closes.

**Task screen**

- Name and schedule summary, e.g. "Mon, Tue, Thu, Fri · 6:00–8:00 PM".
- Current streak and skips left this week, e.g. "1 of 1".
- **This week at a glance**: each scheduled day marked done, skipped, missed, today, or upcoming.
- **Check in** and **Use a skip** buttons.
- Recent check-in photos, leading to the full history.
- Edit button. Editing also offers **Archive habit** and **Delete habit**.

**Archiving and deleting a habit**

- **Archive:** the habit stops reminding and leaves the Today tab. It ends the current streak, but its best streak and all its photos are kept. It can be restored anytime (Streaks tab or Settings).
- **Restore:** the habit comes back with a fresh streak starting from its next scheduled day; its best streak is kept.
- **Delete:** permanently removes the habit, its streaks, and all its photos. Always confirmed first.
- **Delete all data** (Settings): permanently removes every habit, streak, and photo, after two confirmations, then shows the empty Today tab.

**Other screens:** create/edit task, camera → preview, skip confirmation, streak celebration, and full per-task history.

## 6. Tracking progress: streaks

Streaks are the only progress tracking in v1: one per habit (this section) plus the overall day streak the flame follows (section 10). There are no charts, calendars, or recaps yet.

**What counts:**

- A streak grows **only when you check in**. Rest days (unscheduled days) don't count, and neither do skipped days.
- A skipped day **keeps the streak alive but doesn't add to it**.
- If a scheduled day's **window closes with no check-in and no skip used, the streak ends immediately**. The reminders are the safety net, so there's no grace period after the window closes.
- **Longest streak** is saved per task forever.

**How it's displayed:**

- The default format is **weeks and days**, e.g. "3 weeks 2 days" or "3w 2d" where space is tight.
  - **Weeks** = full Monday–Sunday weeks completed, meaning every scheduled day was either checked in or skipped.
    - **Decided:** a streak's **first, partial week** (it started mid-week) counts as a week once that week is over, if every scheduled day from the streak's start was checked in or skipped. E.g. created Wednesday, checked in Wednesday and Friday → "0w 2d" on Friday, "1w" from Monday.
    - **Decided:** a week where **every scheduled day was skipped** (no check-in at all) keeps the streak alive but does **not** add a week.
  - **Days** = check-ins so far in the current week.
- A setting shows **days only** instead, meaning total check-ins in the current streak, e.g. "14 days". It lives in **Settings → Display → "Show streaks as"** (decided), and applies everywhere except the check-in celebration, which always shows days.

**Why no cap on skips is safe:** if a user sets skips equal to all their scheduled days, their streak can't break, but it also can't grow, because only check-ins add to it. The number stalls until they show up.

**Broken streak:** the task card says so plainly and without scolding, e.g. "Streak ended Friday at 3w 3d · Longest: 5w 1d · Starts fresh today". **Decided:** these lines stay on the streak's card until its next check-in.

## 7. Notifications (reminders)

Built in the reminders phase. Local notifications only, scheduled on the phone; no server or push service.

- **Always on for every task.** No per-task toggle in v1.
- **Only on scheduled days, and only while the task isn't checked in or skipped:**
  - **Opens:** when the window opens.
  - **Repeats** during the window, every 10, 15 (default), or 30 minutes (Settings → Reminders → Repeat during window).
  - A **last-call warning** 10, 15 (default), or 30 minutes before the window closes (Settings → Reminders → Last-call warning) that mentions skips. **No normal repeat within 5 minutes before the last call**, and none after it. If the window is too short for a last call after the opening reminder, there's no last call.
- The moment a task is **checked in or skipped**, all of its pending reminders are removed (and any of its reminders still sitting in Notification Center).
- **Tapping a reminder opens the app on the Today tab.** The open task is the hero card there, one tap from the camera.
- **Archived habits never remind.** Deleted ones obviously don't either.
- Wording is kind, never guilt-tripping (exact lines in design.md §6).
- **Reminders always use the real time**, never the DEBUG pretend clock.
- **Last-call warnings are "time sensitive"** where the iPhone allows it, so they can come through a Focus mode. This needs an Apple capability that may not work with a free Apple ID; until it's confirmed on the owner's iPhone they arrive as normal notifications.
- **Asking permission:** never on first launch. Right after the **first streak is created**, a friendly screen (the happy flame: "I'll remind you when your windows open, so your streak never sneaks away.") with **Turn on reminders** (shows the iPhone's permission prompt) and **Not now**. It's shown only once. No bribes or rewards for allowing. If declined, the Settings warning row ("Notifications are off…") handles it.
- **Scheduling:** iOS allows only 64 pending notifications per app, so the app keeps a rolling schedule: the soonest reminders first, stopping at 64. The whole schedule is recalculated when the app opens or comes back, a streak is created, edited, archived, restored, or deleted, a check-in or skip happens, a reminder setting changes, or a day is processed.

## 8. Things it should NOT do (v1)

Deferred (might come later):

- Sharing, friends, shared folders, social feed, nudges
- Smart photo verification (on-device or AI)
- App blocking (Screen Time / FamilyControls)
- Location triggers
- iCloud sync, export/backup (deleting data is in v1; exporting it isn't)
- Insights, recaps, charts
- Apple Watch app, Home Screen widgets
- Public profiles
- AI character or chat assistant
- Multiple time windows per day
- Emergency passes beyond the normal weekly skips

Never:

- Money stakes or paying to keep a streak
- Making photos public, under any setting

Technically out of scope:

- No accounts, logins, servers, or network calls of any kind
- No web technology (Node.js, Python, FastAPI, etc.) — this is a native iPhone app only

---

## Tech stack

| Piece | Choice |
|---|---|
| Language | Swift |
| Screens | SwiftUI |
| Saving data | SwiftData (on the phone only) |
| Minimum iOS | 17 |
| Devices | iPhone only, portrait only |
| Camera | Apple's built-in camera frameworks |
| Reminders | Apple's local notifications |
| Project setup | XcodeGen (`project.yml` is the source of truth; generated `.xcodeproj` is not committed) |
| Editor | VS Code with Apple's Swift extension and SweetPad; Xcode stays installed for its build tools |
| Third-party packages | None without asking the owner first |

## 9. Still open

Decide these with the owner when the relevant phase comes up. Don't guess.

- **Deleting a check-in:** never allowed, allowed only while the window is open, or allowed anytime with the streak recalculated?
- **A task with 0 scheduled days**, or a once-a-week task (weak streak signal). What's the minimum?
- **Checking in more than scheduled** (e.g. an extra gym day): does it count for anything? Leaning no.
- **Photo verification:** when and how (on-device vs. an AI service), and what rejection looks like.

## 10. The flame and the day streak (gamification phase 2)

Built. Looks: `docs/design.md` §2b and §4.14–4.16.

**The day streak** is one overall streak across all your streaks, counted in days.

- It goes **+1** on a day when **every streak scheduled that day is resolved** (checked in or skipped) **and at least one of them was a check-in**. The +1 happens the moment the day's last scheduled item is resolved, not at midnight.
- A day where **everything was skipped** keeps it alive without adding.
- **Rest days** (nothing scheduled) keep it alive without adding.
- It **ends the moment any scheduled window closes** with no check-in and no skip, even if other streaks that day are still open. That day can't add to it any more; the next fully resolved day with a check-in brings it back at 1.
- A streak **created today** counts only from its first window that opens after it was created. If today's window already opened, it starts counting tomorrow (or its next scheduled day).
- **Archived or deleted** streaks stop counting from that moment. Deleting or archiving only affects windows that **haven't closed yet**: once a window has closed with no check-in or skip, that miss counts for the day streak even if the streak is deleted or archived afterwards, and a +1 already earned today stays too. Past days are never recalculated.
- **Saved on the iPhone** (section 11): each finished day's result, the longest day streak, the best flame form ever reached, which break the "streak ended" screen was last shown for, and the last day fully processed. The current day streak is calculated from the saved day results. **Delete all data** resets all of it.

**The flame** is a character drawn in code (no image files) that follows the day streak. It's not an AI and never talks beyond a few fixed, kind lines.

- **Forms** by day streak: Ember 0 · Spark 1–6 · Flame 7–13 · Blaze 14–29 · Bonfire 30–49 · Inferno 50–99 · Wildfire 100–364 · Eternal 365+.
- When the day streak ends, the flame **drops back to Ember**. The **best form ever reached** is remembered and shown on the Flame screen and the "streak ended" screen.
- **Moods**, first match wins:
  1. **Sad** — the day streak ended today and nothing has been checked in since. Lasts until the next check-in.
  2. **Worried** — an open window closes within 15 minutes and isn't done.
  3. **Proud** — everything scheduled today is resolved.
  4. **Sleepy** — rest day.
  5. **Happy** — otherwise.
  6. **Cheering** — only during celebrations.
- **Speech bubble** on Today: one short, always-kind line for the situation (exact lines in design.md §6).
- **After a check-in**, the celebration has up to three steps: the streak's own count (always), the day streak going up (only if that check-in completed the day), and the flame's new form (only if it just reached one). Reaching Spark (0 → 1) is shown inside the day-streak step as "Your flame is back!" (or simply growing), not as a separate new-form step.
- **"Streak ended" screen:** shown **once per break**, the first time the app is opened after the day streak ends — but not if the day streak has already come back by then.

## 11. Saved data, photos, and time passing

Built in the "make it real" phase. A fresh install starts empty. The Design Gallery keeps its own in-memory sample data and never touches saved data.

**What's saved (SwiftData, on the iPhone only).** The saved records are the source of truth; every streak count, longest streak, week circle, skips-left number, day streak, and flame form is **calculated** from them.

- **Streak:** id, name, color, icon, created date, archived date (if archived), and its past archive/restore dates (needed to judge the days it was active).
- **Schedule versions** per streak: weekdays, window start and end (minutes after midnight, local time), skips per week, and the date the version takes effect. **Every day is judged by the version in effect that day.**
  - Changing **days or skips** creates a version that starts **next Monday** (an existing next-Monday version is updated instead).
  - Changing the **window** takes effect **immediately**: from today if today's old window hasn't opened yet, otherwise from tomorrow (decided by the build, so editing can't rescue a window that already opened or closed). A pending next-Monday version gets the new window too.
  - **Brand-new streaks:** until a streak's first window has opened, changes to its days, skips, or window apply **immediately** (there's no history to protect). After that, the rules above apply.
  - The **name, color, and icon** are simply edited.
- **Check-in:** id, streak, day, exact time, photo file name.
- **Skip:** id, streak, day, exact time, refunded (a later check-in that day gave it back).
- **Day results:** one per fully processed day (rest day, all skipped, counted, or broken with the time of the first miss). The day streak is folded from these plus today, so deleting a streak never rewrites past days.
- **App record:** longest day streak, best flame form, the break the "streak ended" screen was last shown for, and the last fully processed day.
- **Settings** stay in simple on-device settings (UserDefaults) and survive restarts.

**Restore** starts a fresh streak from the streak's next scheduled day after the restore day; days while it was archived aren't judged. Its best streak (from earlier active periods) is kept.

**Photos:** each check-in photo is saved as a JPEG (longest side 1600 px, quality 0.7, unique file name) in the app's private storage, never the camera roll. Deleting a streak, or Delete all data, deletes its photo files; archiving keeps them. Settings → Photo storage shows the real count and size.

**Catching up on time passing.** When the app opens, comes back to the foreground, or a window closes while it's open, every day since the last processed day is processed in order (misses, ended streaks, the day streak, the flame form, records). This works even after weeks away.

**Time zones and daylight saving (decided).** All windows follow the iPhone's **current** local time. Days already processed are never re-judged. If a time zone or daylight-saving change **skips over a window entirely** (the clock jumps from before it opens to after it closes), that window doesn't count as a miss for that streak; it's treated like an unscheduled day. Engineering notes: a daylight-saving jump is exact (the window simply doesn't exist that day). A time-zone change is noticed the next time the app is open, and the skipped span is taken to be the hours the clock jumped just before that moment, which is exact when the app is opened soon after landing. Going backwards in time (flying west) never skips anything.

**Saved-data versions.** The saved-data layout is versioned (SwiftData schema versions plus a migration plan), so later phases can add saved data without wiping anything. Version 1 is the layout from the "make it real" phase; version 2 (this phase) adds the record of windows skipped by a clock change and when the app last saw the time zone.

**DEBUG tools** (Settings → Developer, never in the App Store build): a pretend clock that every rule and screen reads "now" from (+15 min, +1 hour, +1 day, +1 week, reset to real time; the pretend time is shown at the top), "Fill with sample data" (a few realistic weeks of streaks, check-ins, skips, and photos added to the real saved data), "Erase everything", "Send test reminder in 5 seconds", and "Show pending reminders". While the pretend clock is on, a bright yellow banner across the top of every screen says so ("Pretend time: Thu 8:01 PM · TAP TO RESET"); tapping it goes back to real time. The simulator keeps a DEBUG-only "Use sample photo" button since it has no camera.

## Coming next (recorded, not built)

These are planned. Nothing for them exists in the app yet.

**Phase 3 — rewards**
- **XP** for every check-in fills a **level bar**.
- Each **level-up**: 9 face-down boxes; you pick **3**. Every box holds **coins** (different amounts). The boxes you didn't pick are never revealed.
- **Coins** buy **accessories** for the flame in a **wardrobe shop**.
- XP, levels, coins, and accessories are **never lost**, even when a streak breaks.
- Coins can **never** be bought with real money.

## Build phases (planned)

One phase at a time. Each phase ends with something runnable.

1. Scaffold: empty app that builds, runs, and passes a test
2. Design system and screens: the look of every screen from `docs/design.md`, filled with sample data (no saving or real logic), plus a DEBUG-only Design Gallery to check every state in the simulator
3. Livelier home and streak celebration: today summary card, hero card for the open task, full-screen streak celebration after a check-in (sample data)
4. App structure: tab bar (Today, Habits, History, Settings), Habits and History tabs, saved settings, archive / restore / delete for habits, delete all data (sample data)
5. Navigation and color: three-tab bar with a raised Today button, Settings behind a gear, a color and icon per streak, week strip and greeting on Today, colored hero card and celebration (sample data)
6. Today cleanup: two tabs (Today, Streaks), History opened from Today, a status line instead of the summary card, an optional name for the greeting, rest days (sample data)
7. Playful restyle: always-dark navy look, Nunito font, chunky 3D buttons and cards, slide-in and confetti animations, haptics, sound effects (sample data)
8. Flame character and day streak (gamification phase 2): day streak rules and saving, the drawn flame with 8 forms and 6 moods, the Today header with a speech bubble, the Flame screen, the 3-step celebration, the "streak ended" screen, the new empty state, and a Flame Lab in the Design Gallery (sample data)
9. Make it real (replaces the old separate Tasks, Check-in, and Streaks-and-skips phases): saved data with SwiftData, real photos and the real camera, every screen on saved data, catching up on days that passed, a DEBUG pretend clock and sample-data tools — see section 11
10. Reminders and fixes: local reminders (window open, repeats, last call, stop on check-in or skip, tap opens Today), the permission screen after the first streak, edits to brand-new streaks, misses that survive deleting, the hero card animation after a check-in, time zone and daylight saving rules, saved-data versioning, and a DEBUG pretend-time banner — see sections 7 and 11
11. Rewards (gamification phase 3): XP, levels, boxes, coins, the wardrobe — see "Coming next"