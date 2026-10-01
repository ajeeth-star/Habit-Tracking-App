# Habit App — Product Context

This is the product reference for the project. When something here conflicts with older notes (including `docs/background.md`, the original concept handoff), **this file wins**. When a product question comes up that this file doesn't answer, stop and ask the owner instead of guessing.

Status: nothing built yet. Version one (v1) scope is defined below.

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

Each task has:

- **A name**, e.g. "Gym".
- **Scheduled days**: any set of weekdays, e.g. Mon, Tue, Thu, Fri.
- **One time window per day**, e.g. 6:00–8:00 PM. The same window applies to every scheduled day. Multiple windows per day are out of v1.
- **Skips per week**, chosen by the user. Any number from 0 up to the number of scheduled days, with no stricter cap (see streak rules for why that's safe).

Tasks are fully independent. Each has its own schedule, skips, streak, and history.

All four fields are set on **one create screen**. Under the skips counter, a plain-language line explains the choice, e.g. "You can miss 1 of your 4 gym days each week and keep your streak." It updates live.

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

**Home screen (the hub)**

- Shows **all tasks** in two sections:
  - **Today**: tasks scheduled today, always **sorted by window start time**. Done tasks stay in place rather than moving.
  - **Not today**: other tasks, each showing when it's next scheduled, e.g. "Next: Friday, 8–10 PM".
- Each task shows a status (open now / done with the check-in time / opens at a time) and its streak.
- A task whose **window is open** is visually highlighted and has **a single "Check in" button** on its card. No skip button on the home screen.
- A **+** button creates a task.
- **Empty state (first launch):** a large + in the middle with "Start your first habit" and a short line about picking days, a window, and skips. No intro or onboarding screens.

**Task screen**

- Name and schedule summary, e.g. "Mon, Tue, Thu, Fri · 6:00–8:00 PM".
- Current streak and skips left this week, e.g. "1 of 1".
- **This week at a glance**: each scheduled day marked done, skipped, missed, today, or upcoming.
- **Check in** and **Use a skip** buttons.
- Recent check-in photos, leading to the full history.
- Edit button.

**Other screens:** create/edit task, camera → preview, skip confirmation, check-in confirmation, and full per-task history.

## 6. Tracking progress: streaks

Streaks are the only progress tracking in v1. There are no charts, calendars, or recaps yet.

**What counts:**

- A streak grows **only when you check in**. Rest days (unscheduled days) don't count, and neither do skipped days.
- A skipped day **keeps the streak alive but doesn't add to it**.
- If a scheduled day's **window closes with no check-in and no skip used, the streak ends immediately**. The reminders are the safety net, so there's no grace period after the window closes.
- **Longest streak** is saved per task forever.

**How it's displayed:**

- The default format is **weeks and days**, e.g. "3 weeks 2 days" or "3w 2d" where space is tight.
  - **Weeks** = full Monday–Sunday weeks completed, meaning every scheduled day was either checked in or skipped.
  - **Days** = check-ins so far in the current week.
- There's a toggle to show **days only**, meaning total check-ins in the current streak, e.g. "14 days".

**Why no cap on skips is safe:** if a user sets skips equal to all their scheduled days, their streak can't break, but it also can't grow, because only check-ins add to it. The number stalls until they show up.

**Broken streak:** the task card says so plainly and without scolding, e.g. "Streak ended Friday at 3w 3d · Longest: 5w 1d · Starts fresh today". How long this message stays is still open (see section 9).

## 7. Notifications

- **Always on for every task.** No per-task toggle in v1.
- **Only on scheduled days, and only if the task isn't already checked in or skipped:**
  - When the window opens.
  - Repeats during the window, roughly every 15 minutes (exact interval is an engineering choice).
  - A **last-call warning about 15 minutes before the window closes** that mentions skips, e.g. "Gym closes at 8. Check in or use a skip (1 left)."
- Reminders **stop** as soon as the task is checked in or skipped.
- **Tapping a notification opens the home screen.** The open task is highlighted there, one tap from the camera.
- Everything is local (scheduled on the phone). No server or push service.
- Engineering note: iOS limits how many notifications an app can have scheduled at once (64), so scheduling has to be done in rolling batches rather than all at once.

## 8. Things it should NOT do (v1)

Deferred (might come later):

- Sharing, friends, shared folders, social feed, nudges
- Smart photo verification (on-device or AI)
- App blocking (Screen Time / FamilyControls)
- Location triggers
- iCloud sync, export/backup
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

- **"Streak ended" message:** does it stay until the next check-in on that task, show once, or stay for the rest of that day?
- **Deleting a check-in:** never allowed, allowed only while the window is open, or allowed anytime with the streak recalculated?
- **Timezones, travel, and daylight saving time:** what happens to windows and streaks.
- **A task with 0 scheduled days**, or a once-a-week task (weak streak signal). What's the minimum?
- **Checking in more than scheduled** (e.g. an extra gym day): does it count for anything? Leaning no.
- **Photo verification:** when and how (on-device vs. an AI service), and what rejection looks like.

## Build phases (planned)

One phase at a time. Each phase ends with something runnable.

1. Scaffold: empty app that builds, runs, and passes a test
2. Design system and screens: the look of every screen from `docs/design.md`, filled with sample data (no saving or real logic), plus a DEBUG-only Design Gallery to check every state in the simulator
3. Tasks: create, edit, list, and save (including the next-week edit rules)
4. Home screen: Today / Not today, status per task, empty state
5. Check-in: in-app camera, preview, window-only rule, photo storage, history
6. Streaks and skips: counting rules, skip confirmation, refunds, broken state, display toggle
7. Reminders: window open, repeats, last call, stop on check-in or skip