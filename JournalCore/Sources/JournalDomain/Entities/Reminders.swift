import Foundation

public enum ReminderAuthorization: Sendable, Equatable {
    case notDetermined
    case authorized
    case denied
}

/// A single one-off reminder notification (BR-R2–R5).
public struct ScheduledReminder: Equatable, Sendable {
    public let identifier: String
    public let day: CalendarDay
    public let fireDate: Date
    public let title: String
    public let body: String
    public let deepLink: DeepLink

    public init(identifier: String, day: CalendarDay, fireDate: Date, title: String, body: String, deepLink: DeepLink) {
        self.identifier = identifier
        self.day = day
        self.fireDate = fireDate
        self.title = title
        self.body = body
        self.deepLink = deepLink
    }
}
