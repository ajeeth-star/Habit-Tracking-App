/// Every piece of user-facing text (design.md §6), so wording can change in one place.
/// Text built from data (streaks, times, schedules) is assembled by `Formatters` from these pieces.
enum Strings {
    static let separator = " · "

    enum Home {
        static let title = "Today"
        static let notTodaySection = "Not today"
        static let createAStreak = "Create a streak"
        static let createTask = "Create streak"
        static let settings = "Settings"
        static let checkIn = "Check in"
        static func next(_ day: String, _ window: String) -> String { "Next: \(day), \(window)" }
        static func streakEnded(_ weekday: String, _ streak: String) -> String { "Streak ended \(weekday) at \(streak)" }
        static func longestStartsFresh(_ streak: String) -> String { "Longest: \(streak) · Starts fresh today" }
        static func longestNextTry(_ streak: String, _ day: String) -> String { "Longest: \(streak) · Next try: \(day)" }
        /// Fills "Streak ended {day} at …" when the miss was today or yesterday.
        static let endedToday = "today"
        static let endedYesterday = "yesterday"
        static func nextDay(_ day: String) -> String { "Next: \(day)" }
    }

    /// Today's status line (design.md §3).
    enum Summary {
        static func doneCount(_ done: Int, _ total: Int) -> String { "\(done) of \(total)" }
        static let doneTodaySuffix = " done today"
        static let allDone = "All done for today"
        static let restDay = "Rest day"
        static func openNow(_ task: String) -> String { "\(task) is open now" }
        static func nextToday(_ task: String, _ time: String) -> String { "Next: \(task) at \(time)" }
        static func nextTomorrow(_ task: String, _ time: String) -> String { "Next: \(task) tomorrow at \(time)" }
        static func nextOn(_ task: String, _ weekday: String, _ time: String) -> String {
            "Next: \(task) \(weekday) at \(time)"
        }
    }

    enum ThisWeek {
        static let title = "This week"
        static let history = "History"
    }

    enum Hero {
        static func closesIn(_ duration: String) -> String { "Closes in \(duration)" }
        static func hoursMinutes(_ h: Int, _ m: Int) -> String { "\(h)h \(m)m" }
        static func hours(_ h: Int) -> String { "\(h)h" }
        static func minutes(_ m: Int) -> String { "\(m)m" }
    }

    enum Tabs {
        static let today = "Today"
        static let streaks = "Streaks"
        static let progress = "Progress"
        static let flame = "Flame"
    }

    enum Today {
        static let comingUp = "Coming up"
        /// The timeline of the day (design.md §4.1).
        static let yourDay = "Your day"
        /// The timeline's "now" marker, shown ALL CAPS.
        static let now = "Now"
        static func nowAt(_ time: String) -> String { "Now, \(time)" }
        static func dayAndTime(_ day: String, _ time: String) -> String { "\(day), \(time)" }
    }

    /// "Done today · 2", "Archived · 1"
    static func counted(_ label: String, _ count: Int) -> String { "\(label) · \(count)" }
    static let expanded = "expanded"
    static let collapsed = "collapsed"

    enum Habits {
        static let title = "Streaks"
        static let active = "Active"
        static let archived = "Archived"
        static let notToday = "Not today"
        static func best(_ streak: String) -> String { "Best: \(streak)" }
        static let bestStreak = "Best streak"
        static let photos = "Photos"
        static let restore = "Restore"
        static let deletePermanently = "Delete permanently"
        static let noArchived = "No archived streaks."
        static func activeCount(_ n: Int) -> String { "\(n) active" }
        static func skipsLeftThisWeek(_ n: Int) -> String {
            switch n {
            case 0: "No skips left this week"
            case 1: "1 skip left this week"
            default: "\(n) skips left this week"
            }
        }
        /// "Best 5w 1d" on a tile.
        static func tileBest(_ streak: String) -> String { "Best \(streak)" }
        static let newStreak = "New streak"
        // A tile's status (the words show ALL CAPS)
        static let open = "Open"
        static let skipped = "Skipped"
        static let missed = "Missed"
        static let done = "Done"
        static let openNow = "Open now"
    }

    enum AllHistory {
        static let title = "History"
        static let all = "All"
        static let today = "Today"
        static let yesterday = "Yesterday"
        static func skipped(_ task: String) -> String { "Skipped \(task)" }
        static func missed(_ task: String) -> String { "Missed \(task)" }
        static func missedStreakEnded(_ task: String, _ streak: String) -> String {
            "Missed \(task) · streak ended at \(streak)"
        }
    }

    enum Settings {
        static let title = "Settings"
        static let you = "You"
        static let yourName = "Your name"
        static let namePlaceholder = "Optional"
        static let nameFooter = "Only used for your greeting. It stays on this iPhone."
        static let display = "Display"
        static let showStreaksAs = "Show streaks as"
        static let weeksAndDays = "Weeks and days"
        static let daysOnly = "Days only"
        static let reminders = "Reminders"
        static let notificationsOff = "Notifications are off. Your streaks can end without a warning."
        static let turnOn = "Turn on"
        static let repeatDuringWindow = "Repeat during window"
        static func every(_ minutes: Int) -> String { "Every \(minutes) min" }
        static let lastCall = "Last-call warning"
        static func before(_ minutes: Int) -> String { "\(minutes) min before" }
        static let remindersFooter = "Reminders are always on for every streak. They stop as soon as you check in or use a skip."
        static let feel = "Feel"
        static let vibrations = "Vibrations"
        static let sounds = "Sounds"
        static let celebrationAnimation = "Celebration animation"
        static let streaks = "Streaks"
        static let archivedHabits = "Archived streaks"
        static let done = "Done"
        static let yourData = "Your data"
        static let photoStorage = "Photo storage"
        static func photoStorageValue(_ count: Int, _ size: String) -> String {
            "\(count) \(count == 1 ? "photo" : "photos") · \(size)"
        }
        static let noPhotos = "No photos"
        static let deleteAllData = "Delete all data"
        static let dataFooter = "Everything stays on this iPhone. Nothing is uploaded."
        static let about = "About"
        static let version = "Version"
        static func versionValue(_ version: String, _ build: String) -> String { "\(version) (\(build))" }
        static let developer = "Developer"
        static let designGallery = "Design Gallery"
    }

    /// Reminder notifications (design.md §4.18): kind, never guilt-tripping.
    enum Reminder {
        static func opensTitle(_ task: String) -> String { "\(task) is open" }
        static func opensBody(_ end: String) -> String { "Until \(end). Snap a photo to keep your streak going." }
        static func repeatTitle(_ task: String, _ left: String) -> String { "\(task) · \(left) left" }
        static func repeatBody(_ end: String) -> String { "Your window closes at \(end)." }
        static func lastCallTitle(_ task: String, _ end: String) -> String { "\(task) closes at \(end)" }
        static func lastCallSkips(_ n: Int) -> String { "Check in or use a skip (\(n) left)." }
        static func lastCallStreak(_ days: Int) -> String { "Last chance to keep your \(days)-day streak." }
        static let lastCallNoStreak = "Last chance to check in today."
        /// Comes after the last scheduled reminder, in case the app isn't opened to schedule more.
        static let safetyNet = "Open the app so I can keep reminding you."
        static let testTitle = "Test reminder"
        static let testBody = "Reminders are working."

        // The permission screen (design.md §4.17)
        static let permissionBubble = "I'll remind you when your windows open, so your streak never sneaks away."
        static let turnOn = "Turn on reminders"
        static let notNow = "Not now"
    }

    /// Settings → Developer (DEBUG builds only).
    enum Developer {
        static let sendTestReminder = "Send test reminder in 5 seconds"
        static let showPendingReminders = "Show pending reminders"
        static let showWelcome = "Show welcome again"
        static let noPendingReminders = "No reminders scheduled."
        static func banner(_ time: String) -> String { "Pretend time: \(time) · TAP TO RESET" }
        static func pretendTime(_ time: String) -> String { "Pretend time: \(time)" }
        static func realTime(_ time: String) -> String { "Real time: \(time)" }
        static let plus15Minutes = "+15 min"
        static let plusHour = "+1 hour"
        static let plusDay = "+1 day"
        static let plusWeek = "+1 week"
        static let resetTime = "Reset to real time"
        static let fillSampleData = "Fill with sample data"
        static let eraseEverything = "Erase everything"
        static let eraseTitle = "Erase everything?"
        static let eraseBody = "All streaks, check-ins, photos, and records are deleted. Settings are kept."
    }

    enum Dialog {
        static let cancel = "Cancel"
        static func archiveTitle(_ task: String) -> String { "Archive \(task)?" }
        static let archiveBody = "It'll stop reminding you and leave your Today screen. Your photos and best streak are kept, and you can restore it anytime from Settings."
        static let archive = "Archive"
        static func deleteTitle(_ task: String) -> String { "Delete \(task)?" }
        static let deleteBody = "This permanently deletes the streak and all its photos."
        static let delete = "Delete"
        static let deleteAllTitle = "Delete everything?"
        static let deleteAllBody = "All streaks and photos will be permanently deleted from this iPhone."
        static let `continue` = "Continue"
        static let deleteAllFinalTitle = "This can't be undone."
        static let deleteEverything = "Delete everything"
    }

    enum Greeting {
        static func withName(_ greeting: String, _ name: String) -> String { "\(greeting), \(name)" }
        static let morning = "Good morning"
        static let afternoon = "Good afternoon"
        static let evening = "Good evening"
    }

    enum WeekStrip {
        static func allDone(_ day: String) -> String { "\(day), all done" }
        static func progress(_ day: String, _ done: Int, _ total: Int) -> String { "\(day), \(done) of \(total) done" }
        static func nothingScheduled(_ day: String) -> String { "\(day), nothing scheduled" }
        static func today(_ day: String, _ done: Int, _ total: Int) -> String { "\(day), today, \(done) of \(total) done" }
        static func opensHistory(_ label: String) -> String { "\(label). Opens history." }
    }

    enum StreakStyle {
        static let section = "Color and icon"

        static func colorName(_ color: StreakColor) -> String {
            switch color {
            case .coral: "Coral"
            case .orange: "Orange"
            case .yellow: "Yellow"
            case .green: "Green"
            case .teal: "Teal"
            case .blue: "Blue"
            case .purple: "Purple"
            case .pink: "Pink"
            }
        }

        /// What VoiceOver calls each streak icon.
        static func iconName(_ symbol: String) -> String {
            iconNames[symbol] ?? "Icon"
        }

        private static let iconNames = [
            "dumbbell.fill": "Dumbbell", "figure.run": "Running", "figure.walk": "Walking",
            "bicycle": "Bicycle", "drop.fill": "Drop", "sparkles": "Sparkles", "book.fill": "Book",
            "pencil": "Pencil", "brain.head.profile": "Brain", "mic.fill": "Microphone",
            "music.note": "Music", "paintbrush.fill": "Paintbrush", "fork.knife": "Fork and knife",
            "cup.and.saucer.fill": "Cup", "leaf.fill": "Leaf", "bed.double.fill": "Bed",
            "moon.fill": "Moon", "sun.max.fill": "Sun", "heart.fill": "Heart",
            "cross.case.fill": "First aid", "house.fill": "House", "cart.fill": "Cart",
            "laptopcomputer": "Laptop", "star.fill": "Star",
        ]
    }

    enum Pill {
        static let open = "Open now"
        static let done = "Done"
        static func doneAt(_ time: String) -> String { "Done \(time)" }
        static func opens(_ time: String) -> String { "Opens \(time)" }
        static let skipped = "Skipped"
        static let missed = "Missed"
    }

    enum Streak {
        static let none = "No streak yet"
        static let shortNone = "0"
        static func weeks(_ n: Int) -> String { n == 1 ? "1 week" : "\(n) weeks" }
        static func days(_ n: Int) -> String { n == 1 ? "1 day" : "\(n) days" }
        static func shortWeeks(_ n: Int) -> String { "\(n)w" }
        static func shortDays(_ n: Int) -> String { "\(n)d" }
    }

    enum Skips {
        static let noneLeft = "No skips left"
        static func left(_ n: Int) -> String { n == 1 ? "1 skip left" : "\(n) skips left" }
        static func count(_ n: Int) -> String { n == 1 ? "1 skip" : "\(n) skips" }
        static func ofTotal(_ left: Int, _ total: Int) -> String { "\(left) of \(total)" }
    }

    enum Schedule {
        static let everyDay = "Every day"
        static let weekdays = "Weekdays"
        static let tomorrow = "Tomorrow"
        static let listSeparator = ", "
    }

    enum Form {
        static let newTitle = "New streak"
        static let editTitle = "Edit streak"
        static let cancel = "Cancel"
        static let name = "Name"
        static let namePlaceholder = "e.g. Gym"
        static let whichDays = "Which days"
        static let timeWindow = "Time window"
        static let from = "From"
        static let to = "To"
        static let skipsPerWeek = "Skips per week"
        static let create = "Create streak"
        static let save = "Save changes"
        static let endBeforeStart = "End time must be after start time."
        static let archiveHabit = "Archive streak"
        static let deleteHabit = "Delete streak"
        static let fallbackTaskName = "streak"
        static let decreaseSkips = "Fewer skips"
        static let increaseSkips = "More skips"
        static func noSkips(_ name: String) -> String { "No skips — every \(name) day counts." }
        static func someSkips(_ skips: Int, _ days: Int, _ name: String) -> String {
            "You can miss \(skips) of your \(days) \(name) \(days == 1 ? "day" : "days") each week and keep your streak."
        }
        static func allSkips(_ name: String) -> String {
            "You can skip every \(name) day. Your streak won't break — but it won't grow either."
        }
        static func nextWeek(_ new: String, _ current: String) -> String {
            "Starting next week: \(new) (this week: \(current))."
        }
    }

    enum Detail {
        static let back = "Back"
        static let edit = "Edit"
        static let streak = "Streak"
        static let skipsLeftThisWeek = "Skips left this week"
        static func longest(_ streak: String) -> String { "Longest: \(streak)" }
        static let thisWeek = "This week"
        static let checkIn = "Check in"
        static let useSkip = "Use a skip"
        static let recentCheckIns = "Recent check-ins"
        static let seeAll = "See all"
        static let noCheckIns = "No check-ins yet."
        static func opens(_ time: String) -> String { "Opens \(time)" }
        static let closed = "Closed"
        static let doneToday = "Done today"
        static let noSkipsLeft = "No skips left"
    }

    enum Skip {
        static let lastTitle = "Use your last skip?"
        static let title = "Use a skip?"
        static let keep = "Keep my skip"
        static let use = "Use skip"
        static func daysLeft(_ n: Int, _ name: String) -> String {
            "You have \(n) \(name) \(n == 1 ? "day" : "days") left this week, including today."
        }
        static func makeItOn(_ weekday: String) -> String {
            "If you skip today, you'll have to make it \(weekday) to keep your streak."
        }
        static let checkInEveryDay = "If you skip today, you'll need to check in every remaining day this week to keep your streak."
        static let noneUntilMonday = "This keeps your streak, but you'll have no skips left until Monday."
        static func leftAfter(_ n: Int) -> String {
            "You'll have \(n) \(n == 1 ? "skip" : "skips") left this week after this."
        }
    }

    enum Camera {
        static func header(_ task: String, _ time: String) -> String { "\(task) · closes \(time)" }
        static func windowClosed(_ time: String) -> String { "The window closed at \(time)." }
        static let useSamplePhoto = "Use sample photo"
        static let accessOff = "Camera access is off. Turn it on in Settings to check in with a photo."
        static let openSettings = "Open Settings"
        static let close = "Close camera"
        static let takePhoto = "Take photo"
        static let switchCamera = "Switch camera"
        static let retake = "Retake"
        static let submit = "Submit"
    }

    enum Celebration {
        static func done(_ task: String) -> String { "\(task) done" }
        static func moreToFinish(_ n: Int) -> String { "\(n) more to finish the week" }
        static let weekComplete = "Week complete"
        static func skipBack(_ n: Int) -> String { "Your skip is back — \(n) \(n == 1 ? "skip" : "skips") left" }
        /// "Gym streak", shown ALL CAPS under the streak's count.
        static func streakName(_ task: String) -> String { "\(task) streak" }
        static let flameBack = "Your flame is back!"
        static func becameForm(_ form: String) -> String { "Your flame became a \(form)!" }
        static let `continue` = "Continue"
    }

    /// The flame character, its screen, and Today's header (design.md §2b, §4.1, §4.14).
    enum Flame {
        static let title = "Your flame"
        static let dayStreak = "Day streak"
        static func dayStreakCount(_ n: Int) -> String { n == 1 ? "1 day streak" : "\(n) day streak" }
        static func daysTo(_ n: Int, _ form: String) -> String { n == 1 ? "1 day to \(form)" : "\(n) days to \(form)" }
        static let finalForm = "You've reached the final form."
        static let forms = "Forms"
        static let locked = "Locked"
        static let current = "Current"
        static let longest = "Longest"
        static let bestForm = "Best form"
        static let opensFlame = "Opens the Flame tab"
        /// Floats above the sleepy flame.
        static let sleepZ = "z"
        static func accessibility(_ form: String, _ mood: String, _ streak: String?) -> String {
            ["Your flame.", "\(form) form.", "\(mood).", streak.map { "\($0)." }].compactMap { $0 }.joined(separator: " ")
        }

        static func formName(_ form: FlameForm) -> String {
            switch form {
            case .ember: "Ember"
            case .spark: "Spark"
            case .flame: "Flame"
            case .blaze: "Blaze"
            case .bonfire: "Bonfire"
            case .inferno: "Inferno"
            case .wildfire: "Wildfire"
            case .eternal: "Eternal"
            }
        }

        /// One line about each form's look, for the "new form" celebration step.
        static func formDescription(_ form: FlameForm) -> String {
            switch form {
            case .ember: "A small, warm ember."
            case .spark: "A tiny spark with two flickering tongues."
            case .flame: "Taller, with a bright golden core."
            case .blaze: "Bigger, with four tongues and a soft glow."
            case .bonfire: "Five tongues, a warm glow, and embers floating up."
            case .inferno: "Red-hot edges and a white-hot core."
            case .wildfire: "Purple-tipped tongues and sparkles all around."
            case .eternal: "Blue and white, with sparkles in orbit."
            }
        }

        static func moodName(_ mood: FlameMood) -> String {
            switch mood {
            case .happy: "Happy"
            case .proud: "Proud"
            case .sleepy: "Sleepy"
            case .worried: "Worried"
            case .sad: "Sad"
            case .cheering: "Cheering"
            }
        }
    }

    /// What the flame says in Today's speech bubble (design.md §4.1). Pools hold the lines to pick from.
    enum Bubble {
        static let streakEnded = "That's okay. One check-in brings me back."
        static func closingSoon(_ task: String, _ minutes: Int) -> String {
            "\(task) closes in \(minutes) min! Quick, snap a photo!"
        }
        static func open(_ task: String) -> [String] {
            ["\(task) is open — let's do this!", "Time for \(task.lowercased()). I'm ready when you are."]
        }
        static func upcoming(_ task: String, _ time: String) -> String { "Next up: \(task) at \(time)." }
        static let allDone = ["All done today. I'm glowing!", "That's everything. Proud of you."]
        static let restDay = "Rest day. Recharging for tomorrow."
        static let dayOver = "That's it for today. See you next time!"
        static let empty = "Hi! I'm your flame. Create a streak and help me grow."
        static let firstStreak = "Our first streak! Check in during its window to light me up."
    }

    /// The "Popular streaks" chips on the empty state (design.md §4.2).
    enum Starters {
        static let title = "Popular streaks"
        static let hint = "Opens a new streak, filled in"
        static let gym = "Gym"
        static let skincare = "Morning skincare"
        static let read = "Read"
        static let journal = "Journal"
        static let water = "Drink water"
        static let walk = "Walk"
        static let study = "Study"
        static let cleanUp = "Clean up"
    }

    /// The Progress tab (design.md §4.19).
    enum Progress {
        static let title = "Progress"
        static let viewAllPhotos = "View all photos"
        static let previousMonth = "Previous month"
        static let nextMonth = "Next month"
        static let thisMonth = "This month"
        static let checkIns = "Check-ins"
        static let completionRate = "Completion rate"
        static let perfectDays = "Perfect days"
        static let longestDayStreak = "Longest day streak"
        static let yourStreaks = "Your streaks"
        static let lastThirtyDays = "Last 30 days"
        static func percent(_ n: Int) -> String { "\(n)%" }
        static let noRate = "—"
        static func streakRate(_ task: String, _ rate: String) -> String { "\(task), \(rate) over the last 30 days" }
        /// "Tuesdays are your strongest day (92%)", given the weekday's plural.
        static func bestDay(_ weekdays: String, _ rate: String) -> String {
            "\(weekdays) are your strongest day (\(rate))"
        }
        static func weekdayPlural(_ weekday: String) -> String { "\(weekday)s" }
        static let empty = "Check in for a few days and your progress shows up here."
        // Calendar days, for VoiceOver
        static func allDone(_ date: String) -> String { "\(date), all done" }
        static func progress(_ date: String, _ done: Int, _ total: Int) -> String { "\(date), \(done) of \(total) done" }
        static func missed(_ date: String) -> String { "\(date), missed" }
        static func nothingScheduled(_ date: String) -> String { "\(date), nothing scheduled" }
        static func today(_ date: String, _ done: Int, _ total: Int) -> String { "\(date), today, \(done) of \(total) done" }
    }

    /// The welcome screens on a fresh install (design.md §4.20).
    enum Welcome {
        static let skip = "Skip"
        static let hello = "Hi! I'm your flame. I grow every day you show up."
        static let howItWorks = "Pick a time for each habit, then snap a photo during it to prove you did it."
        static let skips = "Life happens, so you get a few skips each week. Ready? Let's light this up!"
        static let `continue` = "Continue"
        static let letsGo = "Let's go"
        static func page(_ n: Int, _ count: Int) -> String { "Page \(n) of \(count)" }
    }

    /// The "day streak ended" screen (design.md §4.15).
    enum DayStreakEnded {
        static func title(_ n: Int) -> String { "Your \(n)-day streak ended" }
        static func stats(_ longest: String, _ form: String) -> String { "Longest: \(longest) · Best form: \(form)" }
        static let bubble = "One check-in brings me back."
        static let letsGo = "Let's go"
    }

    enum History {
        static func title(_ task: String) -> String { "\(task) History" }
        static let empty = "No check-ins yet. Your photos will show up here."
        static let close = "Close"
        static let nothingScheduled = "Nothing scheduled"
        static let noCheckIns = "No check-ins"
    }

    enum Accessibility {
        static func streak(_ value: String) -> String { "Streak \(value)" }
        static func weekDay(_ day: String, _ status: String) -> String { "\(day), \(status)" }
        static let done = "done"
        static let skipped = "skipped"
        static let missed = "missed"
        static let today = "today"
        static let upcoming = "upcoming"
        static let photo = "Check-in photo"
    }
}
