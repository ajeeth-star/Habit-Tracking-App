/// Every piece of user-facing text (design.md §6), so wording can change in one place.
/// Text built from data (streaks, times, schedules) is assembled by `Formatters` from these pieces.
enum Strings {
    static let separator = " · "

    enum Home {
        static let title = "Today"
        static let todaySection = "Today"
        static let notTodaySection = "Not today"
        static let emptyTitle = "Start your first streak"
        static let emptyBody = "Pick the days, a time window, and how many skips you get each week."
        static let createTask = "Create streak"
        static let settings = "Settings"
        static let checkIn = "Check in"
        static func next(_ day: String, _ window: String) -> String { "Next: \(day), \(window)" }
        static func streakEnded(_ weekday: String, _ streak: String) -> String { "Streak ended \(weekday) at \(streak)" }
        static func longestStartsFresh(_ streak: String) -> String { "Longest: \(streak) · Starts fresh today" }
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
    }

    enum Today {
        static let comingUp = "Coming up"
        static let doneToday = "Done today"
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
            "pencil": "Pencil", "brain.head.profile": "Brain", "guitars.fill": "Guitar",
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
        static let shortNone = "—"
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
        static let close = "Close camera"
        static let takePhoto = "Take photo"
        static let switchCamera = "Switch camera"
        static let retake = "Retake"
        static let submit = "Submit"
    }

    enum Celebration {
        static let dayStreak = "day streak"
        static func done(_ task: String) -> String { "\(task) done" }
        static func moreToFinish(_ n: Int) -> String { "\(n) more to finish the week" }
        static let weekComplete = "Week complete"
        static func skipBack(_ n: Int) -> String { "Your skip is back — \(n) \(n == 1 ? "skip" : "skips") left" }
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
