/// Every piece of user-facing text (design.md §6), so wording can change in one place.
/// Text built from data (streaks, times, schedules) is assembled by `Formatters` from these pieces.
enum Strings {
    static let separator = " · "

    enum Home {
        static let title = "Today"
        static let todaySection = "Today"
        static let notTodaySection = "Not today"
        static let emptyTitle = "Start your first habit"
        static let emptyBody = "Pick the days, a time window, and how many skips you get each week."
        static let createTask = "Create task"
        static let checkIn = "Check in"
        static func closes(_ time: String) -> String { "Closes \(time)" }
        static func checkedIn(_ time: String) -> String { "Checked in \(time)" }
        static func next(_ day: String, _ window: String) -> String { "Next: \(day), \(window)" }
        static func streakEnded(_ weekday: String, _ streak: String) -> String { "Streak ended \(weekday) at \(streak)" }
        static func longestStartsFresh(_ streak: String) -> String { "Longest: \(streak) · Starts fresh today" }
    }

    enum Pill {
        static let open = "Open now"
        static let done = "Done"
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
        static let newTitle = "New task"
        static let editTitle = "Edit task"
        static let cancel = "Cancel"
        static let name = "Name"
        static let namePlaceholder = "e.g. Gym"
        static let whichDays = "Which days"
        static let timeWindow = "Time window"
        static let from = "From"
        static let to = "To"
        static let skipsPerWeek = "Skips per week"
        static let create = "Create task"
        static let save = "Save changes"
        static let endBeforeStart = "End time must be after start time."
        static let fallbackTaskName = "task"
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
        static let toggleStreakHint = "Switches between weeks and days"
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

    enum Success {
        static func done(_ task: String) -> String { "\(task) done" }
        static func streak(_ streak: String) -> String { "Streak: \(streak)" }
        static func moreToFinish(_ n: Int) -> String { "\(n) more to finish the week" }
        static let weekComplete = "Week complete"
        static func skipBack(_ n: Int) -> String { "Your skip is back — \(n) \(n == 1 ? "skip" : "skips") left" }
        static let backToToday = "Back to today"
    }

    enum History {
        static func title(_ task: String) -> String { "\(task) History" }
        static let empty = "No check-ins yet. Your photos will show up here."
        static let close = "Close"
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
