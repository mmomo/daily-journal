import Foundation

/// Builds the rolling 7-day reminder window (BR-R1–R5). Pure; scheduling happens through `ReminderScheduler`.
public enum ReminderPlanner {
    public static let windowDays = 7
    public static let title = "Time to journal"
    public static let baseBody = "Your daily prompt is waiting."

    public static func plan(
        settings: ReminderSettings,
        isAuthorized: Bool,
        streak: StreakSummary,
        now: Date,
        timeZone: TimeZone
    ) -> [ScheduledReminder] {
        guard settings.isEnabled, isAuthorized else { return [] }                 // BR-R1
        let today = CalendarDay(containing: now, timeZone: timeZone)
        var reminders: [ScheduledReminder] = []
        for offset in 0..<windowDays {
            let day = today.adding(days: offset)
            let fire = DayMath.instant(on: day, hour: settings.hour, minute: settings.minute, in: timeZone)
            guard fire > now else { continue }
            if offset == 0 && streak.isTodayDone { continue }                      // BR-R2
            var body = baseBody
            if offset == 0, streak.status == .active, streak.current >= 1 {        // BR-R4
                body += " Keep your \(streak.current)-day streak going."
            }
            reminders.append(ScheduledReminder(
                identifier: "reminder-\(day.key)",
                day: day,
                fireDate: fire,
                title: title,
                body: body,
                deepLink: .todayEditor                                             // BR-R5
            ))
        }
        return reminders
    }
}
